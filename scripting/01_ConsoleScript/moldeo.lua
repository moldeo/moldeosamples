--[[

	##############################
	MOLDEO LUA SCRIPT UTILITY
	##############################

	GPL: see moldeo.org
	DESCRIPTION: general utility functions to handle programmning within MoldeObject's lua scripting
	DATE: 13/06/2012
--]]

--[[

	#####
	UTILS
	#####

	Timing and messages functions

		--Run timing function
		function RunClock( this )

		--Log message per second/halfsecond/frame
		function Message( this, string_message )
--]]


function MoldeoGlobals(this)

	this.ResourceManager = this:GetResourceManager()

	if (this.ResourceManager==nil) then
		this:PushDebugString("MoldeoGlobals:: Error ResourceManager")
	end

	if (this.ResourceManager) then
		this.TextureManager = this.ResourceManager:GetTextureMan()
		if (this.TextureManager==nil) then
			this:PushDebugString("MoldeoGlobals:: Error TextureManager")
		else
			this.texturecount = this.TextureManager:GetTextureCount()
			this:PushDebugString( "MoldeoGlobals:: texcount: "..this.texturecount )
		end

		this.VideoManager = this.ResourceManager:GetVideoMan()
		if (this.VideoManager==nil) then
			this:PushDebugString("MoldeoGlobals:: Error VideoManager")
		else
			this.videobufferpathcount = this.VideoManager:GetVideoBufferPathCount()
			this:PushDebugString( "MoldeoGlobals:: videobufferpathcount: "..this.videobufferpathcount )
		end
	end

	this.luap = moLuaP5()		

	if (this.luap==nil) then
		this:PushDebugString("Error moLuaP5()")
	end

	this.ticks = 0

	--seconds
	this.seconds = 0
	this.lastseconds = 0

	--halfseconds
	this.halfseconds = 0
	this.lasthalfseconds = 0

	--frames
	this.frames = 0
	this.lastframes = 0

	this.moscript_states = {}
	this.moscript_objects = {}
	this.moscript_objects_members = {}


	-- states: fadein, fadeout, stop
	this.fades_state = {}

	-- alpha channel 0 .. 1
	this.fades_alpha = {}

	--in millis, duration
	this.fades_name = {}
	this.fades_time = {}
	this.fades_time_start = {}
	this.fades_duration = {}
	this.fades_dataindex = {}




	-- states: fadein, fadeout, stop
	this.popups_state = {}

	-- alpha channel 0 .. 1
	this.popups_alpha = {}

	--in millis, duration
	this.popups_name = {}
	this.popups_time = {}
	this.popups_time_start = {}
	this.popups_start = {}
	this.popups_duration = {}
	this.popups_dataindex = {}

end


--Run timing function
function RunClock( this )

	this.lastseconds = this.seconds

	this.ticks = this:GetTicks()
	this.seconds = math.floor( this.ticks / 1000 )  --1 sec = 1000 ms
	this.halfseconds = math.floor( this.ticks / 500 ) --0.5 sec = 500 ms
	this.frames = math.floor( this.ticks / 30 )  --1 frame = 30 ms
end


function Debug( this, string_message )

	this:PushDebugString(string_message)

end


--Log message per second/halfsecond/frame
function Message( this, string_message )

	this.dif = this.seconds - this.lastseconds
	this.difhalf = this.halfseconds -  this.lasthalfseconds

	if ( this.dif > 0 ) then
		if ( math.mod( this.seconds, 2) == 0 ) then
			this:PushDebugString(string_message)
		end
	end	

end


--[[
	#######
	STATE
	#######

]]


function AddObject( this, moldeo_label )
	if (this.moscript_objects~=nil) then
		this.moscript_objects[moldeo_label] = -1 --undefined
		this.moscript_objects[moldeo_label] = this:GetObjectId( moldeo_label )

		if (this.moscript_objects[moldeo_label]>=0) then
			return this.moscript_objects[moldeo_label]
		end

		this:PushDebugString( "moldeo.lua error: AddObject("..moldeo_label..")")
	end
	this:PushDebugString( "moldeo.lua error: AddObject("..moldeo_label..")")
	return -1
end

function GetObject( this, moldeo_label )
	if ( this.moscript_objects~=nil) then
		if ( this.moscript_objects[moldeo_label]==nil)   then
			this:PushDebugString(" moldeo.lua:: GetObject > error! nil value for "..moldeo_label )
			return nil
		else
			return this.moscript_objects[moldeo_label]
		end
	end
end

function AddMember( this, moldeo_label, member_name )
	
	memberlbl = moldeo_label..":"..member_name

	this.moscript_objects_members[memberlbl] = -1  --undefined
	this.moscript_objects_members[memberlbl] = this:GetObjectDataIndex( GetObject( this, moldeo_label ), member_name )
	if (this.moscript_objects_members[memberlbl]>0) then
		return this.moscript_objects_members[memberlbl]
	end

	Debug( this, "moldeo.lua error: AddMember("..moldeo_label..","..member_name..")")

	return -1
end

function GetMember( this, moldeo_label, member_name )

	memberlbl = moldeo_label..":"..member_name
	if ( this.moscript_objects_members[memberlbl]~=nil) then
		if this.moscript_objects_members[memberlbl]<=0 then			
			return -1
		else
			return this.moscript_objects_members[memberlbl]
		end
	else
		this:PushDebugString("moldeo.lua > GetMember : Error : memberlbl"..memberlbl)
	end
end


function GetMemberValue( this, moldeo_label, member_name )
	return this:GetObjectData( GetObject( this, moldeo_label ), GetMember( this, moldeo_label, member_name))
end


function SetMemberValue( this, moldeo_label, member_name, member_value )

	idobject = GetObject( this, moldeo_label )
	idmember = GetMember( this, moldeo_label, member_name)
	if (idobject>=0 and idmember>=0) then
		this:SetObjectData( idobject, idmember, member_value )
	else
		this:PushDebugString("moldeo.lua: SetMemberValue: ERROR! label:"..moldeo_label.." param:"..member_name )
	end
end


--- Each an interactive state describe a sub-cicle in  the all interactive global life time
--Time in an interactive installation is cyclic, it's the same story repeated and iterated.
--The system thyself can evolve too, so that every new cycle story is everyway somewhat different than the other ones... never exactly the same...

--Each state has:

-- A SCENE: a group of fx/objects
	--each object has his events/scripts that may run eternally or with some conditions...
-- A CONDITION


function AddState( this, state_string )
	this.moscript_states[state_string] = { substates=nil, status="stopped", timer_init=0, timer_time=0 }
	this.actual_state = ""
	this.actual_substate = ""
end

function GetState( this, state_string)
	stateobj = nil

	if (this.moscript_states[state_string]~=nil) then
		stateobj = this.moscript_states[state_string]
	end

	return stateobj
end


function GetActualState( this )

	state_string = ActualStateString(this)
	return GetState(this,state_string)
end


function AddSubState( this, state_string, substate_string )

	this.actual_substate = ""

	if (this.moscript_states[state_string].substates==nil) then	
		--create substates table
		this.moscript_states[state_string].substates = {}
	end

	this.moscript_states[state_string].substates[substate_string] = { status="stopped", timer_init=0, timer_time=0 }
	
end

function GetSubState( this, state_string, substate_string )
	stateobj = nil
	substateobj = nil

	if (this.moscript_states[state_string]~=nil) then
		stateobj = this.moscript_states[state_string]
		if (stateobj.substates~=nil) then
			substateobj = this.moscript_states[state_string].substates[substate_string]
			if (substateobj~=nil) then
				return substateobj
			end
		end
	end

	return substateobj
end

function GetActualSubState( this )

	state_string = ActualStateString(this)
	substate_string = ActualSubStateString(this)
	return GetSubState( this, state_string, substate_string )
end


function SetActualState(this, state_string)
	this.actual_state = state_string
	--substate empty when setting state
	this.actual_substate = ""
	if (state_string~="") then
		if (this.moscript_states[state_string]~=nil) then
			if (this.moscript_states[state_string].status=="stopped") then
				StartState( this, state_string)
			end
		end
	end
end

function SetActualSubState(this, state_string, substate_string )

	SetActualState( this, state_string )

	if (this.moscript_states[state_string]~=nil) then
		if (this.moscript_states[state_string].substates~=nil) then
			if (this.moscript_states[state_string].substates[substate_string]~=nil) then
				this.actual_substate = substate_string
				StartSubState( this, state_string, substate_string )
			end
		end
	end
end

function ActualStateString(this)
	return this.actual_state
end

function ActualSubStateString(this)
	return this.actual_substate
end

function StopAllStates( this )
	for st,obj in pairs(this.moscript_states) do
		StopState( this, st )
	end
end

function StopState( this, state_string)
	this.moscript_states[state_string].status = "stopped"
	if (this.moscript_states[state_string].substates~=nil) then
		for subst,obj in pairs(this.moscript_states[state_string].substates) do
			StopSubState( this, state_string, subst )
		end
	end
end

function StopSubState( this, state_string, substate_string )
	if (this.moscript_states[state_string].substates[substate_string]~=nil) then
		this.moscript_states[state_string].substates[substate_string].status = "stopped"
	end
end


function RunAllStates( this, state_string )
	for st,obj in pairs(this.moscript_states) do
		--this:PushDebugString("Running state:"..st.." status:"..obj.status)
		RunState( this, st )

	end
end

function RunState( this, state_string )
	if (this.moscript_states[ state_string ]~=nil) then
		if (this.moscript_states[ state_string ].status=="playing") then
			if (this.moscript_states[state_string].timer_init==nil) then
				this.moscript_states[state_string].timer_init = 0
			end
			this.moscript_states[ state_string ].timer_time =  this.ticks - this.moscript_states[state_string].timer_init
			if (this.moscript_states[ state_string ].substates~=nil) then
				RunAllSubStates( this, state_string)
			end
		end
	else
		this:PushDebugString("moldeo.lua::RunState > ERROR: state "..state_string.." doesnt exists.")
	end
end

function RunSubState( this, state_string, substate_string )
	if (this.moscript_states[ state_string ]~=nil) then
		if (this.moscript_states[ state_string ].substates[substate_string]~=nil) then
			if (this.moscript_states[ state_string ].substates[substate_string].status=="playing") then
				substate = this.moscript_states[state_string].substates[substate_string]
				--substate.status = "playing"
				substate.timer_time = this.ticks - substate.timer_init
				this.moscript_states[state_string].substates[substate_string] = substate
			end
		else
			this:PushDebugString("moldeo.lua::RunSubState > ERROR: substate "..substate_string.." doesnt exists in state "..state_string)
		end	

	else
		this:PushDebugString("moldeo.lua::RunSubState > ERROR: state "..state_string.." doesnt exists.")
	end
end

function RunAllSubStates( this, state_string )
	if (this.moscript_states[ state_string ]~=nil) then
		if (this.moscript_states[ state_string ].substates~=nil) then
			for subs,obj in pairs(this.moscript_states[ state_string ].substates) do
				RunSubState( this, state_string, subs )
			end	
		end
	end
end

function GetTimerState(this, state_string )
	if (this.moscript_states[ state_string ]~=nil) then
		RunState( this, state_string )
		return this.moscript_states[state_string].timer_time
	else
		this:PushDebugString("moldeo.lua::GetTimerState > ERROR: state "..state_string.." doesnt exists.")
	end

end

function GetTimerSubState(this, state_string, substate_string )
	if (this.moscript_states[ state_string ]~=nil) then
		if (this.moscript_states[ state_string ].substates[substate_string]~=nil) then
			RunSubState( this, state_string, substate_string )
			return this.moscript_states[state_string].timer_time
		else
			this:PushDebugString("moldeo.lua::GetTimerSubState > ERROR: substate "..substate_string.." doesnt exists in state "..state_string)
		end
	else
		this:PushDebugString("moldeo.lua::GetTimerSubState > ERROR: state "..state_string.." doesnt exists.")
	end

end

function ResetState( this, state_string )
	if (this.moscript_states[ state_string ]~=nil) then
		this.moscript_states[state_string].timer_init = 0
	else
		this:PushDebugString("moldeo.lua::RunState > ERROR: state "..state_string.." doesnt exists.")
	end
end


function StartState( this, state_string )
	--end other states, timer?
	StopAllStates(this)

	if (state_string=="") then
		return
	end	

	if (this.moscript_states[state_string]~=nil) then
		this.moscript_states[state_string].timer_init = this.ticks
		this.moscript_states[state_string].timer_time = 0
		this.moscript_states[state_string].status = "playing"
	else
		this:PushDebugString("moldeo.lua::StartState > ERROR: state "..state_string.." doesnt exists.")
	end

end

function StartSubState( this, state_string, substate_string )


	if (this.actual_state == state_string) then
		if (this.moscript_states[state_string]~=nil) then

			if ( this.moscript_states[state_string].status == "stopped" ) then
				StartState( this, state_string )
			end

			if (this.moscript_states[state_string].substates[substate_string]~=nil) then
				this.moscript_states[state_string].substates[substate_string].status = "playing"
				this.moscript_states[state_string].substates[substate_string].timer_init = this.ticks
				this.moscript_states[state_string].substates[substate_string].timer_time = 0
			else
				this:PushDebugString("moldeo.lua::StartSubState > substate "..substate_string.." doesnt exists in state "..state_string)
			end
		end
	end
end


--[[
	#####
	FADES
	#####
	*************************************

--]]


function FadeObjects(this)

	--recorre los fades y los ejecuta
	for k,v in pairs(this.fades_state) do
	

	  o_time = this.fades_time[k]
	  o_time_start = this.fades_time_start[k]
	  o_duration = this.fades_duration[k]
	  o_alpha = this.fades_alpha[k]
	  o_state = this.fades_state[k]
	  o_dataindex = this.fades_dataindex[k]
	  o_name = this.fades_name[k]

	  --this:PushDebugString("k:"..k.." o_state:"..o_state.." o_name:"..o_name)
	
	  if ( o_state == "fadein" ) then
		
		o_time = this.ticks - o_time_start
		
		if (o_time < 0 ) then
			o_time = 0
		end
		
		if ( o_time > o_duration or o_time == o_duration ) then
			o_alpha = 1.0
			o_state = "stop"
			this:ObjectEnable( k )
			this:SetObjectData( k, o_dataindex, o_alpha )
		else
			o_alpha = o_time / o_duration
			o_state = "fadein"
			this:ObjectEnable( k )
		end
		
	  end
	
	  if ( o_state == "fadeout" ) then
		
		o_time = this.ticks - o_time_start
		
		if (o_time < 0 ) then
			o_time = 0
		end
		
		if ( o_time > o_duration or o_time==o_duration) then
			o_alpha = 0.0
			o_state = "stop"
			this:ObjectDisable( k )
			this:SetObjectData( k, o_dataindex, o_alpha )
		else
			o_alpha = 1.0 - o_time / o_duration
			o_state = "fadeout"
			this:ObjectEnable( k )
		end
		
	  end	

		this.fades_state[k] = o_state
		this.fades_alpha[k] = o_alpha
		this.fades_duration[k] = o_duration
		this.fades_time[k] = o_time

	  if ( o_state == "fadein" or o_state=="fadeout" ) then
		--this:PushDebugString("k:"..k.." name:"..o_name.." o_state:"..o_state.." o_alpha:"..o_alpha)
		this:SetObjectData( k, o_dataindex, o_alpha )
	  end
	  --[[
	  --reasignamos
		
		
		if ( k > -1 and o_dataindex > -1 ) then
			
		end
	--]]
	end
	
	
	
end



function FadeIn( this, objectid, name, duration )
--en timing milis, hacer fade del objeto
	if (objectid~=nil) then
		if (objectid>-1) then

		--this:PushDebugString("start fadein:"..objectid)


		--if (this.fades_state[objectid]=="stop" or this.fades_state[objectid]=="fadeout") then
			this.fades_name[objectid] = name
			if ( this.fades_state[objectid]~="fadeout" ) then
				this.fades_alpha[objectid] = 0.0
			end
			this.fades_state[objectid] = "fadein"
			--this.popups_state[objectid] = "fadein"
			--this.fades_alpha[objectid] = 0.0
			this.fades_duration[objectid] = duration
			this.fades_time[objectid] = this.ticks
			this.fades_time_start[objectid] = this.ticks

			this.fades_dataindex[objectid] = this:GetObjectDataIndex( objectid,"alpha")
		--end
		else
			this:PushDebugString("CANT fadein:"..name)
		end
	end
end

function FadeOut( this, objectid, name, duration )
	if (objectid>-1) then
	--this:PushDebugString("start fadeout:"..objectid)
	--if (this.fades_state[objectid]=="stop" or this.fades_state[objectid]=="fadein") then
		this.fades_name[objectid] = name
		if ( not (this.fades_state[objectid]=="fadein") ) then
			this.fades_alpha[objectid] = 1.0
		end		
		this.fades_state[objectid] = "fadeout"
		--this.popups_state[objectid] = "fadeout"
		--this.fades_alpha[objectid] = 1.0
		this.fades_duration[objectid] = duration
		this.fades_time[objectid] = this.ticks
		this.fades_time_start[objectid] = this.ticks
		this.fades_dataindex[objectid] = this:GetObjectDataIndex( objectid,"alpha")
	--end
	else
		this:PushDebugString("CANT fadeout:"..name)
	end
end


function FadeVolumeIn( this, objectid, name, duration )
--en timing milis, hacer fade del objeto
	if (objectid>-1) then

	this:PushDebugString("start fadevolumein:"..objectid)

	--if (this.fades_state[objectid]=="stop" or this.fades_state[objectid]=="fadeout") then
		this.fades_name[objectid] = name
		this.fades_state[objectid] = "fadein"
		--if (this.fades_alpha[objectid]<=0.0 or this.fades_alpha[objectid]>=1.0) then this.fades_alpha[objectid] = 0.0 end
		this.fades_alpha[objectid] = 0.0
		this.fades_duration[objectid] = duration
		this.fades_time[objectid] = this.ticks
		this.fades_time_start[objectid] = this.ticks
		this.fades_dataindex[objectid] = this:GetObjectDataIndex( objectid,"volume")
	--end
	else
		this:PushDebugString("CANT fadevolumein:"..name)
	end
end


function FadeVolumeOut( this, objectid, name, duration )
	if (objectid>-1) then
	this:PushDebugString("start fadevolumeout:"..objectid)
	--if (this.fades_state[objectid]=="stop" or this.fades_state[objectid]=="fadein") then
		this.fades_name[objectid] = name
		this.fades_state[objectid] = "fadeout"
		--if (this.fades_alpha[objectid]<=0.0 or this.fades_alpha[objectid]>=1.0) then  this.fades_alpha[objectid] = 1.0 end
		this.fades_alpha[objectid] = 1.0
		this.fades_duration[objectid] = duration
		this.fades_time[objectid] = this.ticks
		this.fades_time_start[objectid] = this.ticks
		this.fades_dataindex[objectid] = this:GetObjectDataIndex( objectid,"volume")
	--end
	else
		this:PushDebugString("CANT fadevolumeout:"..name)
	end
end



--[[************************************

		POPUPS

****************************************--]]


function PopUpObjects(this)

	for k,v in pairs(this.popups_state) do

		o_time = this.popups_time[k]
		o_time_start = this.popups_time_start[k]

		o_start = this.popups_start[k]
		o_duration = this.popups_duration[k]

		o_alpha = this.popups_alpha[k]
		o_state = this.popups_state[k]
		o_dataindex = this.popups_dataindex[k]

		o_name = this.popups_name[k]

		if ( o_state == "popup" ) then

			o_time = this.ticks - o_time_start

			if (o_time < 0 ) then
				o_time = 0
			end

			if ( o_time > o_start ) then
				o_state = "popwait"	
				o_alpha = 1.0
				this:ObjectEnable( k )
				this:SetObjectData( k, o_dataindex, o_alpha )
			end
		end

		if (o_state == "popwait" and o_duration > 0) then

			o_time = this.ticks - o_time_start

			if ( o_time > (o_start + o_duration) ) then
				o_alpha = 0.0
				o_state = "stop"				
				this:SetObjectData( k, o_dataindex, o_alpha )
				this:ObjectDisable( k )
			end
		end

		


			this.popups_state[k] = o_state
			this.popups_alpha[k] = o_alpha
			this.popups_time[k] = o_time

			--if (dif>0) then
				--this:PushDebugString("popup:"..this.popups_name[k].." time:"..this.popups_time[k].." stoptime:"..(o_start + o_duration))
			--end

	end
end


function PopUp( this, objectid, name, start, duration )

	if (objectid>-1) then
		this:PushDebugString("start popup:"..objectid)
		this.popups_name[objectid] = name
		this.popups_state[objectid] = "popup"
		this.popups_alpha[objectid] = 0.0
		this.popups_start[objectid] = start
		this.popups_duration[objectid] = duration
		this.popups_time[objectid] = this.ticks
		this.popups_time_start[objectid] = this.ticks
		this.popups_dataindex[objectid] = this:GetObjectDataIndex( objectid,"alpha")
	else
		this:PushDebugString("CANT popup:"..name)
	end

end


-- explode(seperator, string)
function explode(d,p)
  local t, ll
  t={}
  ll=0
  if(#p == 1) then return {p} end
    while true do
      l=string.find(p,d,ll,true) -- find the next d in the string
      if l~=nil then -- if "not not" found then..
        table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
        ll=l+1 -- save just after where we found it for searching next time.
      else
        table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
        break -- Break at end, as it should be, according to the lua manual.
      end
    end
  return t
end

