-- author sid 
-- architm21@gmail.com 


local log = ngx.log
local err = ngx.ERR
local status = ngx.status
local say = ngx.say
local body = ''
local id = ''
local decode = ngx.decode_base64

-- loading modules 
local memcached = require "resty.memcached"
local cassa_manager = require "cassandra_manager"


-- imageid(this is the id of the image in cassandra) from the uri 
local imageId = ngx.var.uri:match( "cimage/([^/]+)/?$" );
if not imageId then
  log(err, "faulty image id:",imageId )
  status = 400
  say("invalid request");
  do return end
end

-- getting access token, organisation id , user id from request header
local accesstoken = ngx.req.get_headers()['appaccesstoken']
local user_id = ngx.req.get_headers()['userId']
local org_id = ngx.req.get_headers()['orgId']
if  accesstoken and user_id and org_id then 
local status = cassa_manager.do_validate(accesstoken,user_id,org_id)
if status == true then 
    local rows = cassa_manager.do_content(imageId)
    if  not rows then
      log(err, 'could not retrieve images: ', err)
      return ngx.exit(500)
    else
      local content = rows[1].content
      status = 200
      ngx.header.content_type = rows[1].content_type
      local body = decode(content)
      ngx.header["Content-Length"] = #body
      say(body)
      do return end
    end
else
    say("invalid access token")
    do return end
end
end
-- getting cookie 
local cookie = ngx.var.cookie_PHPSESSID;
if not cookie then
  status = 500
  say("Authentication failed");
  do return end
end

-- authenticating user 
local memc = memcached:new()
memc:set_timeout(1000) -- 1000 ms
local ok, err = memc:connect("192.168.8.35",11211)

if not ok then
  log(err, "failed to connect memcache:", err)
  status = 500
  say("Internal server error");
  do return end
end

local res, flags, err = memc:get("memc.sess.key." .. cookie)
if err then
  log(err, "failed to get key: ", err)
  status = 500
  say("Internal server error");
  do return end
end

if not res then
  log(err, "key not found in memcache " .. cookie)
  status = 500
  say("Internal server error");
  do return end
else
  st, en, orgId, cap2, cap3 = string.find(res,"s:5:\"orgid\";s:%d:\"(%d+)\"");
  if not orgId then
    log(INFO, "No Org id");
    status = 500
    say("Internal server error");
  do return end
  end
end


local ok, err = memc:set_keepalive(0, 800)
if not ok then
  log(err, "failed to set keepalive: ", err)
end

local rows = cassa_manager.do_content(imageId)

if not rows and row == ngx.null then
  log(err, 'could not retrieve images: ', err)
  return ngx.exit(500)
end
if  rows == ngx.null then
  log(err, "did not got rows",rows[0])
else 
  
local organisation_id = rows[1].org_id 
local content = rows[1].content
if organisation_id == orgId then
  status = 200
  ngx.header.content_type = rows[1].content_type
  body = decode(content)
  ngx.header["Content-Length"] = #body
  say(body)
else
  log(INFO, "Org id mismatch");
  status = 500
  say("Authentication failed");
end
end 

