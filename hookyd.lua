#!/usr/bin/env luvit
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

local JSON  = require("json")
local table = require("table")
local fs    = require("fs")
local os    = require("os")
local str   = require("string")
local timer = require("timer")
local Lever = require("./lever")
local Job   = require("./job")

local lever = Lever:new()

-- ping pong endpoint
function ping(req,res)
  res:writeHead(200,{})
  res:finish("{\"ping\":\"pong\"}")
end

-- pkill endpoint
function pkill(req,res,pass)

	-- use the job attach to run a command that is not a hook
	Job.attach("pkill","-u","1001",function(code,body)

		-- pkill returns 1 when no more processes can be killed
		if code == 0 then

			-- give the system a bit of time to spawn new processes
			timer.setTimeout(1000,pkill,req,res,pass)
		else

			-- send a response that the pkill was sucessfull
			local response = JSON.stringify({exit = code, out = body})
	      res:writeHead(200, {
	        ["Content-Type"] = "application/json",
	        ["Content-Length"] = #response
	      })
	      res:finish(response)
			pass()
		end
	end)
end

-- run or attach to a running hook
function run_hook(req,res)
  
    -- combine all chunks into the payload
    local payload = table.concat(req.user.chunks, "")

    -- attach to a job
    Job.attach(lever.user.hooky,req.env.hook_id,payload,function(code,body)

      
      -- check if the hooky script ran out of memory
      if str.match(body, 'ENOMEM') or str.match(body, 'out of memory') then
        code = 3
      end

      -- send response
      local response = JSON.stringify({exit = code, out = body})
      res:writeHead(200, {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #response
      })
      res:finish(response)
    end)
end

function capture_body(req,res,pass)
  local chunks = {}

  -- eat up the entire body
  req:on('data', function (chunk, len)
    if chunks then
      chunks[#chunks + 1] = chunk
    end
  end)

  -- on error clear out all chunks stored
  req:once('error',function ()
    chunks = nil
  end)

  -- request has completely been read in
  req:once('end', function ()
    req.user.chunks = chunks
    chunks = nil
    pass()
  end)
end

function ensure_hook(req,res,pass)
  -- we need to make sure the hook exists that we are trying to run
  fs.exists(lever.user.hook_dir .. "/" .. req.env.hook_id .. ".rb",function(err,exists)

    if not exists then
      res:writeHead(404, {})
      res:finish()
    else
      pass()
    end
  end)
end


-- routing endpoints
lever:all("/ping",ping)
lever:all("/pkill",pkill)
lever:post("/hooks/?hook_id",capture_body,ensure_hook,run_hook)
lever:put("/hooks/?hook_id",capture_body,ensure_hook,run_hook)

function logger(req,res,pass)
  p(os.date("%c"),req.socket._handle:getpeername(),req.url)
  pass()
end

lever:add_middleware(logger)

function validate(config)
  local passed = true

  if not config.hooky then
    print("'hooky' parameter is missing in config file")
    passed = false
  end

  if not config.hook_dir then
    print("'hooky_dir' parameter is missing in config file")
    passed = false
  end

  if not config.port then
    print("'port' parameter is missing in config file")
    passed = false
  end

  return passed
end

fs.readFile("/opt/local/etc/hookyd/hookyd.conf",function(err,data)
  if not err then
    lever.user = JSON.parse(data)

    if validate(lever.user) then

      -- start server
      lever:listen(lever.user.port,lever.user.ip)

      process:on('error', function(err)
        p("global error: ",{err=err})
      end)
    end
  else
    p("unable to read config file",err)
  end
end)