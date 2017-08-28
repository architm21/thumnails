local log = ngx.log
local err = ngx.ERR
local status = ngx.status
local cassandra = require "cassandra"
local Cluster = require 'resty.cassandra.cluster'

local cluster_instance

local _M = {}

function _M.do_init()
  local cluster, err = Cluster.new {
    shm = 'cassandra', -- defined by the lua_shared_dict directive
    contact_points ={'ip1 ','ip2'},
    connect_timeout = 1000,
    timeout_read = 1000,
  }
  if err then
    log(err, 'could not create connection', err)
  end
  cluster_instance = cluster
end
--- getting image from cassandra 
function _M.getImage(imageId)
  id = cassandra.uuid(imageId)
  local rows, err, cql_code = cluster_instance:execute("SELECT * FROM keysapce.image_details WHERE id=?", {id})
  if err then
   log(ERROR, 'could not execute query', err)
  end
  return rows ;
end

return _M
