-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 1; st-rulers: [70] -*-
-- vim: ts=4 sw=4 ft=lua noet
---------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2014, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   3 Sept 2014 by Daniel Barney <daniel@pagodabox.com>
---------------------------------------------------------------------

local spawn   = require('childprocess').spawn
local table   = require("table")
local os      = require('os')
local Emitter = require('core').Emitter

-- this is a class definition
local Job = {}
Job.__index = Job

-- storage of all running jobs
local jobs = {}

function Job.attach (hooky,hook,payload,cb)
  local self = jobs[hook]
  if not self then
    -- this is how objects are built in lua
    self = {
	    hooky = hooky,
      hook = hook,
      payload = payload,
      listeners = Emitter:new()}
    self = setmetatable(self, Job)

    -- store the job
    jobs[hook] = self

    -- run the job
    self:run()
  end

  -- register user callback
  self.listeners:on("done",cb)

  -- clear out job from global list
  self.listeners:on("done",function ()
    jobs[hook] = nil
  end)
  return self;
end

function Job:run()
  local child = spawn(self.hooky, {self.hook,self.payload})
  local response = {}

  -- eat up all chunks of the response
  child.stdout:on('data', function(chunk)
    response[#response + 1] = chunk
  end)

  -- eat up all chunks of the response
  child.stderr:on('data', function(chunk)
    response[#response + 1] = chunk
  end)

  -- when the child exists
  child:once('exit',function(code)

    -- combine all chunks
    local body = table.concat(response, "")
    response = nil;

    -- call all registered listeners with the exit code and the hook body
    self.listeners:emit('done',code,body)
  end)
end


return Job;