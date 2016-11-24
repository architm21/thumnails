-- author Archit M D 
-- architm21@gmail.com 

local log = ngx.log
local ERROR = ngx.ERR
local status = ngx.status
local say = ngx.say
local body = ''
local id = ''
local content_type = ngx.header.content_type
local decode = ngx.decode_base64
local content_length = ngx.header["Content-Length"]

-- loading modules 
local memcached = require "resty.memcached"
local cassandra = require "cassandra"
local Cluster = require 'resty.cassandra.cluster'

-- imageid(this is the id of the image in cassandra) from the uri 
local imageId = ngx.var.uri:match( "cimage/([^/]+)/?$" );
if not imageId then
  log(ERROR, "faulty image id:",imageId )
  status = 400
  say("invalid request");
  do return end
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
local ok, err = memc:connect("192.168.8.27",11211)

if not ok then
  log(ERROR, "failed to connect memcache:", err)
  status = 500
  say("Internal server error");
  do return end
end

local res, flags, err = memc:get("memc.sess.key." .. cookie)
if err then
  log(ERROR, "failed to get key: ", err)
  status = 500
  say("Internal server error");
  do return end
end

if not res then
  log(ERROR, "key not found in memcache " .. cookie)
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
  log(ERROR, "failed to set keepalive: ", err)
end

-- establishing connection with cluster 
local cluster, err = Cluster.new {
  shm = 'cassandra', -- defined by the lua_shared_dict directive
  contact_points = {'192.168.8.33', '192.168.8.11','192.168.8.60'},
  keyspace = 'cordiant_images',
  connect_timeout = 1000,
  timeout_read = 1000,
}


if not cluster then
  log(ERROR, 'could not create cluster: ', err)
  say("could not create cluster")
end

id = cassandra.uuid(imageId)
-- execution of query 
local rows, err, cql_code = cluster:execute("SELECT * FROM image_details WHERE id=?",{id})

if not rows and row == ngx.null then
  log(ERROR, 'could not retrieve images: ', err)
  return ngx.exit(500)
end
if  not rows then
  log(ERROR, "did not got rows","")
end 


local organisation_id = rows[1].org_id 
local content = rows[1].content
if organisation_id == orgId then
  status = 200
  content_type = rows[1].content_type
  body = decode(content)
  content_length = #body
  say(body)
else
  log(INFO, "Org id mismatch");
  status = 500
  say("Authentication failed");
end