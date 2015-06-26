-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 1; st-rulers: [70] -*-
-- vim: ts=4 sw=4 ft=lua noet
---------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2015, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   26 June 2015 by Daniel Barney <daniel@pagodabox.com>
---------------------------------------------------------------------

local spawn = require('coro-spawn')
local split = require('coro-split')

-- adapted from the lit source
local function exec(command, ...)
  local child = spawn(command, {
    args = {...},
    -- Tell spawn to create coroutine pipes for stdout and stderr only
    stdio = {nil, true, true}
  })
  local output, code, signal = {}, nil, nil


  -- Split the coroutine into three sub-coroutines and wait for all three.
  split(function ()
    for data in child.stdout.read do
      output[#output + 1] = data
    end
  end, function ()
    for data in child.stderr.read do
      output[#output + 1] = data
    end
  end, function ()
    code, signal = child.waitExit()
  end)

  return table.concat(output), code, signal
end

local running_jobs = {}

function exports.attach(cmd, arg, payload)
	local waiters = running_jobs[arg]
	if waiters then
		waiters[#waiters + 1] = coroutine.running()
		return coroutine.yield()
	else
		waiters = {}
		running_jobs[arg] = waiters
		local output, code = exec(cmd, arg, payload)

		-- send the output to all coroutines that are paused
		for _, waiter in pairs(waiters) do
			coroutine.resume(waiter, output, code)
		end

		running_jobs[arg] = nil
		return output, code
	end
end