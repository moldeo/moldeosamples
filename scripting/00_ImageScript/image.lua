texture_param_id = -1
alpha_param_id = -1
texture_value_id = -1
texture_value_count = 0
random_value = 0
last_sec = 0
Math = moLuaMath()

function this.Init(this)

end

function this.Run(this)
	--
	--this:PushDebugString( "Image. lua Run!" )
	
	ticks = this:GetTicks()
	texture_param_id = this:GetParamIndex( "texture")
	alpha_param_id = this:GetInletIndex( "alpha" )
		
	if ( texture_param_id > -1 ) then
		texture_value_id =  this:GetCurrentValue( texture_param_id )
		texture_value_count = this:GetValuesCount( texture_param_id )
	end

	
	--random_value = Math:UnitRandom(0)
	--random_value = math.random()
	--random_value = math.random(0,1)
	
	if ( math.floor(ticks/1000)>last_sec ) then

		this:PushDebugString( "alpha_param_id: "..alpha_param_id.." texture_param_id:"..texture_param_id.." texture_value_id:"..texture_value_id.."/"..texture_value_count )

		random_value = math.random( 1, texture_value_count ) - 1

		last_sec = math.floor( ticks/1000 )
		
	end

	alphadata = this:GetInletData( alpha_param_id )
	this:SetInletData( alpha_param_id, 0.15 )
	alphadata2 = this:GetInletData( alpha_param_id )
	this:PushDebugString( "alphadata2: "..alphadata2 )

	
	this:SetCurrentValue( texture_param_id, random_value )
end


function this.Update(this, nparts, nfeats, nvalids )

	--nparticulas = nparts
	--this:PushDebugString( "Image. lua update!" )

end