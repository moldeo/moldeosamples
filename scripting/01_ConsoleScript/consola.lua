--install sudo apt-get install lua-filesystem   lua-filesystem-dev

--local lfs = require "lfs"

moldeolua = ""
moldeolua = ConsoleDataPath.."moldeo.lua"
dofile (moldeolua)

function this.Init(this, offset)
	
	--CODIGO DE INICIALIZACION DE UTILIDADES DE moldeo.lua
	MoldeoGlobals( this )

	Debug( this, "Console script: Guion Cosecha: ok moldeo.lua:"..moldeolua)
	Debug( this, "Console script: Guion Cosecha: MoldeoAppPath:"..MoldeoAppPath)
	
	AddObject( this, "imageA" )
	AddMember( this, "imageA", "alpha")
	AddObject( this, "imageB" )
	AddMember( this, "imageB", "alpha")
	
	AddState( this, "muestraB")
	AddState( this, "transicionBA")
	AddState( this, "muestraA")
	AddState( this, "transicionAB")

end



function this.Run(this)

	RunClock( this )
	RunAllStates( this )
	FadeObjects(this)

	stateobj = GetActualState(this)
	estado = ActualStateString(this)

	--muestra estado actual
	if (stateobj~=nil) then
		Message( this, "consola.lua::Run > states:"..estado.." status"..stateobj.status.." timer_init:"..stateobj.timer_init.." timer_time:"..stateobj.timer_time )
	end
	--Message( this, "consola.lua::Run > states:"..estado )
	

	if (estado=="") then

		SetActualState( this, "muestraA" )
	
	elseif ( estado=="muestraA" ) then

		if ( GetTimerState(this,"muestraA")>4000 ) then
			SetActualState( this, "transicionAB" )
			
			FadeOut( this, GetObject(this, "imageA"),"alpha",2000)
			FadeIn( this, GetObject(this, "imageB"),"alpha",2000)
			
		end	
	elseif ( estado=="transicionAB" ) then

		if ( GetTimerState(this,"transicionAB")>2000 ) then
			SetActualState( this, "muestraB" )			

		end	
	elseif ( estado=="muestraB" ) then

		if ( GetTimerState(this,"muestraB")>4000 ) then

			SetActualState( this, "transicionBA" )

			FadeIn( this, GetObject(this, "imageA"),"alpha",2000)
			FadeOut( this, GetObject(this, "imageB"),"alpha",2000)

		end	

	elseif ( estado=="transicionBA" ) then

		if ( GetTimerState(this,"transicionBA")>2000 ) then
			SetActualState( this, "muestraA" )
		end	

	end

end


function this.Draw(this)
--[[
	--Message( this, "ORIENTATIONX"..ORIENTATIONX )
	if (this.luap~=nil) then

		if (this.actual_state=="cargador" and this.load_percent~=nil) then
			this.luap:strokeWeight( 80.0 )
			this.luap:stroke( 1.0, 1.0, 1.0, 0.5 )
			this.luap:line( -0.49, -0.3, -0.49+this.load_percent*0.01, -0.2 )
		end


		this.luap:strokeWeight( 2.0 )
		this.luap:noFill();

		if (LHC~=nil) then
			if (LHC>0.5) then
				--verde
				this.luap:stroke( 1.0, 1.0, 1.0, 0.5 )
				this.luap:strokeWeight( 2.0 )
				this.luap:ellipse( LHX_n, LHY_n, 0.02, 0.02, 36 )
			end
		end
	end
--]]
end



function this.Finish(this)
    --this:PushDebugString("Hello from Finish")
end
