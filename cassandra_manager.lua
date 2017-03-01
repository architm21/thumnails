local log = ngx.log
local ERROR = ngx.ERR
local status = ngx.status
local cassandra = require "cassandra"
local Cluster = require 'resty.cassandra.cluster'

local cluster_instance

local _M = {}

function _M.do_init()
  local cluster, err = Cluster.new {
    shm = 'cassandra', -- defined by the lua_shared_dict directive
    contact_points ={'35.154.51.82'},
    connect_timeout = 1000,
    timeout_read = 1000,
  }
  if err then
    log(ERROR, 'could not create connection', err)
  end

  cluster_instance = cluster
end

function _M.do_content(imageId)
  id = cassandra.uuid(imageId)
  local rows, err, cql_code = cluster_instance:execute("SELECT * FROM cordiant_images.image_details WHERE id=?", {id})
  if err then
   log(ERROR, 'could not execute query', err)
  end
  return rows ;
end
function _M.do_validate(accesstoken,user_id,org_id)
  local success = false 
  local id = tonumber(user_id)
  -- serialization of id to bigint
  local cassandra_id= cassandra.bigint(id)
  local rows, err, cql_code = cluster_instance:execute("SELECT access_tokens FROM ekam.userdetails_"..org_id.." WHERE  userid=?", { cassandra_id})
  if err then 
    log(ERROR, "error creating connection",err )
    return success
  else
    local access_tokens = rows[1].access_tokens
    for key,value in pairs(access_tokens) do
      if value == accesstoken then
      success = true 
      end
    end
    return success
end
end

return _M
