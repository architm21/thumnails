-- author sid 
local log = ngx.log
local ERROR = ngx.ERR
local status = ngx.status
local say = ngx.say
local body = ''
local id = ''
local decode = ngx.decode_base64

local cassa_manager = require "cassandra_manager"

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
 local authorised =  cassa_manager.validateUserBycookie(cookie)
 if not authorised then 
 status  = 500;
 say("Authentication failed");
 do return end
end

-- getting image deatils 
local rows = cassa_manager.getImage(imageId)

if not rows and row == ngx.null then
  log(ERROR, 'could not retrieve images: ', err)
  return ngx.exit(500)
end
if  rows == ngx.null then
  log(ERROR, "did not got rows",rows[0])
else 
  
local organisation_id = rows[1].org_id 
local content = rows[1].content
if organisation_id then
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
