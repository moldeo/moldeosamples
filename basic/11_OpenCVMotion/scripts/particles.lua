

moldeolua = ""
moldeolua = ConsoleDataPath.."/scripts/moldeo.lua"
log = print
dofile (moldeolua)



nparticulas = 0

particles_fractal = {}
fractal_directions = {}

ticks_local = 0.0
dt_local = 0.0

local seconds = 0
local lastseconds = 0
local halfseconds = 0
local lasthalfseconds = 0
local frames = 0
local dif = 0
local difhalf = 0

freq_change = 1
freq_change = 1000

--[[

Cada franja de particulas/rama:
	400 particulas
	divididas en 4 ramas

	400 / 4 = 4 grupos 0..100, 100..200, 200..300, 300..400
	100 / 4
	50 /


	ngrupos

--]]

--modelo
svgparticulas = {}
imageindex = 1
--svgparticulas[1] = { sx=1.0, sy=1.0, angle=1.57, tx=0.0, ty=0.0 }
prototipo_xml_file = ConsoleDataPath.."/scripts/prototipo2.svg"

local xmlTree,err = XmlParser:ParseXmlFile(prototipo_xml_file);

for i,xmlNode in pairs(xmlTree.ChildNodes) do
    print(xmlNode.Name)
    if(xmlNode.Name=="image") then
        print(xmlNode.Attributes)
        svgparticulas[imageindex] = { id="", sx=1.0, sy=1.0, angle=0.0, tx=0.0, ty=0.0, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
		for name,value in pairs(xmlNode.Attributes) do
            print(name..": "..value)
            svgparticulas[imageindex][name] = value
        end
        svgparticulas[imageindex]["sx"] = svgparticulas[imageindex]["width"] / 1024
        svgparticulas[imageindex]["sy"] = svgparticulas[imageindex]["height"] / 600
        svgparticulas[imageindex]["tx"] = 6.0*( svgparticulas[imageindex]["x"]+svgparticulas[imageindex]["width"]/2 - 1024/2) / 1024
        svgparticulas[imageindex]["ty"] = 4.0*( -svgparticulas[imageindex]["y"]-svgparticulas[imageindex]["height"]/2 +600/2) / 600
        svgparticulas[imageindex]["angle"] = 0.0
        print(svgparticulas[imageindex])
        imageindex = imageindex + 1
    end
end
--dump(xmlTree)

--[[
svgparticulas[1] = { id="use3952", sx=0.99999999049849, sy=0.99999999049849, angle=2.5887312941311, tx=2.53708089728, ty=-2.465783362919, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[2] = { id="use3954", sx=0.99999999728756, sy=0.99999999728756, angle=4.1947185028914, tx=-2.0404472890644, ty=1.6260462407067, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[3] = { id="use3956", sx=0.99999999324219, sy=0.99999999324219, angle=5.3125822283884, tx=-2.3154464535621, ty=1.3129818837749, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[4] = { id="use3958", sx=0.9999999972302, sy=0.9999999972302, angle=1.450032797968, tx=-2.2214262049381, ty=1.1246386287408, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[5] = { id="use3960", sx=0.99999999148431, sy=0.99999999148431, angle=3.7482871964031, tx=3.4636742741377, ty=1.4410520038078, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[6] = { id="use3962", sx=1.000000003897, sy=1.000000003897, angle=1.941676979881, tx=2.3621883755404, ty=-2.5198559069114, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[7] = { id="use3964", sx=0.99999999372219, sy=0.99999999372219, angle=5.8014778021048, tx=2.2534983997926, ty=-2.3796673871239, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[8] = { id="use3966", sx=1.0000000070172, sy=1.0000000070172, angle=5.8985394038083, tx=2.4828466391197, ty=-2.7503456856189, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
svgparticulas[9] = { id="use3968", sx=1.564669817521, sy=1.564669817521, angle=2.268285394457, tx=1.8699872333033, ty=-0.56854935659813, forming=false, breaking=false, force_x=0.0, force_y=0.0, rotation_v=0.0, forming_timer=0.0 }
--]]

grupos = {}
ngrupos = 1
ngrupos_iterados=0

iterationfunctions = {}
niterationfunctions = 10

--tiempo en milisegundos entre cada REPRODUCCION
minage_for_next_iteration = 3000

g_i0 = 0
g_i1 = 0


--===========================================
maxage_index = -1
maxage = 0
actual_age = 0
forming_clock = 0.0

particlessvg = {}
particlessvg["forming"] = { index=0, value=0.0 }
particlessvg["forming_speed"] = { index=0, value=0.0 }
particlessvg["speed_reaction"] = { index=0, value=0.0 }
particlessvg["motion_sensitivity"] = { index=0, value=0.0 }
particlessvg["motion_sight"] = { index=0, value=0.0 }

grupos_reseted = false
tindex = -1
luap5 = nil

function ResetGrupos(this)

	if (grupos_reseted) then
		return;
	end

	nparticulas = this:GetParticleCount()
	grupos_reseted = true

	ResetParticles(this)
	FormParticles(this)

end

function ResetParticles(this)
	for k,v in pairs(svgparticulas) do
		this:UpdateParticleRotation( k-1, 0.0, 0.0, 0.0 )
	end
end

function FormParticles(this)
	for k,v in pairs(svgparticulas) do
		v["forming_timer"] = 0.0
		v["forming"] = true
		v["breaking"] = false
		svgparticulas[k] = v
	end
end

function BreakParticles(this)
	for k,v in pairs(svgparticulas) do
		v["forming_timer"] = 0.0
		v["forming"] = false
		v["breaking"] = true
		svgparticulas[k] = v
	end
end

function this.Init(this)

	this:PushDebugString("Init prototipo_xml_file OK")
    log("hi log lua en moldeo")

	--Cuando se quiere el valor propiamente dicho de un parametro mas que andar seleccionado diferentes preconfiguraciones o valores
	--se usa el Inlet de ese parametro que tiene el mismo nombre que este

	maxage = 400000
	maxage_index = this:GetInletIndex("maxage")

	if (maxage_index>-1) then
		this:SetInletData( maxageindex, maxage )
		maxage = this:GetInletData( maxageindex )
		--this:PushDebugString("maxage_index: "..maxage_index.." maxage: "..maxage)
	end


	for key,val in pairs(particlessvg) do
		index = val.index
		value = val.value
		--this:PushDebugString(key..": "..index.." value: "..value)
		index = this:GetInletIndex( key )
		value = this:GetInletData( index )
		--this:PushDebugString(key..": "..index.." value: "..value)
		val.index = index
		val.value = value
		particlessvg[key] = val
	end

	--translatex_id = this:GetInletIndex("translatex")
	--translatey_id = this:GetInletIndex("translatey")

	--Siempre resetea el grupo al Iniciar o Reiniciar el script
	grupos_reseted = false

	ResetGrupos(this)
	this:PushDebugString("nparticulas: "..nparticulas)

 	tindex = this:GetTrackerSystemData()
    if ( tindex == -1 ) then
		this:PushDebugString("Warning no tracker index")
    end

	luap5 = moLuaP5()
	this:PushDebugString( "moLuaP5:PPI() = "..luap5:PPI())

end


function this.Run(this)
    --this:PushDebugString("Hello from Run")
	--ticks = ticks+10

	ticks_local =  math.floor( ticks_local + dt_local )
	--ticks_local =  this:GetTicks()

	seconds = math.floor( ticks_local / 1000 )

	halfseconds = math.floor( ticks_local / 500 )
	frames = math.floor( ticks_local / 30 )


	dif = seconds - lastseconds
	difhalf = halfseconds -  lasthalfseconds
	if ( difhalf > 0 ) then
	end

	if ( dif > 0 ) then
		this:PushDebugString("seconds:"..seconds)
	end

	lastseconds = seconds
	lasthalfseconds = halfseconds

end




function this.RunSystem(this, nparts )
	--tx = this:GetInletData( translatex_id )
	--ty = this:GetInletData( translatey_id )

end

function this.RunParticle(this, i, dt)

	--posicion de la particula i
	x,y,z = this:GetParticlePosition( i )


	--velocidad de la particula i
	vx,vy,vz = this:GetParticleVelocity( i )

	--tamaño
	w,h = this:GetParticleSize( i )
	--w,h = this:GetParticleSize( i )

	--edad , visibilidad, masa de la particula i
	age,visible,mass = this:GetParticle( i )

	rx,ry,rz = this:GetParticleRotation( i )
    
    op = this:GetParticleOpacity(i)

	if ( svgparticulas[i+1]) then

		actual_age = age
		obj = svgparticulas[i+1]

		tx = obj["tx"]
		ty = obj["ty"]
		sx = obj["sx"]
		sy = obj["sy"]
		angle = obj["angle"]
		forming = obj["forming"]
		forming_timer = obj["forming_timer"]
		breaking = obj["breaking"]
		rotation_v = obj["rotation_v"]

		g_forming = particlessvg["forming"]
		g_forming_speed = particlessvg["forming_speed"]
		g_motion_sensitivity = particlessvg["motion_sensitivity"]
		g_motion_sight = particlessvg["motion_sight"]

		interpol = 0

		if ( n_in_motions > g_motion_sensitivity.value ) then
			for m=1,n_in_motions do
				--calculate distance to this particle...
				motion = in_motions[m]

				gest_particule_x = x - motion["x"]
				gest_particule_y = y - motion["y"]

				gest_particule_norm = math.sqrt( gest_particule_x*gest_particule_x + gest_particule_y*gest_particule_y)
				if ( gest_particule_norm < g_motion_sight.value ) then
					--afectamos la particula...
					--this:PushDebugString("Afectamos particulas")
					breaking = true
					forming_timer = 0.0

					vel = math.min( 100.0, 10.0 / gest_particule_norm )
					rotation_v = 10.0*math.random()
                    opacity = 1.0


					vx = vel * gest_particule_x
					vy = vel * gest_particule_y
					vz = (0.5-math.random())*3.0

					--this:UpdateParticleVelocity( i, vx, vy, 0.0 )
					--this:UpdateParticleRotation( i, 0.0, 0.0, rz + rotation_v )
                    this:UpdateParticleOpacity( i, opacity )
					--this:PushDebugString("vel="..vel)
				end
			end
		end


		if ( g_forming.value == 1 and breaking==false ) then

			--create interpolation between actual position and tx,ty,sx,sy,angle
			--forming_clock
			if (forming_timer < g_forming_speed.value ) then
				forming_timer = forming_timer + dt_local
			end

			interpol = math.max( 0.0001, forming_timer / g_forming_speed.value )

			--Translation
			tx_a = x + ( tx - x ) * interpol
			ty_a = y + ( ty - y ) * interpol
			tz_a = z + ( 0.0 - z ) * interpol
			rotation_v = rotation_v + ( 0.0 - rotation_v) * interpol

			--Rotation
			angle = angle*180.0/3.1415
			rz_a = rz + rotation_v + ( angle - rz ) * interpol
            opacity = op + ( 0.0 - op) * interpol

			this:UpdateParticlePosition( i, tx_a, ty_a, 0.0 )

			this:UpdateParticleSize( i, sx, sy )
			--this:UpdateParticleRotation( i, 0.0, 0.0, rz_a )
            this:UpdateParticleOpacity( i, opacity )
			--this:UpdateParticleVelocity( i, 0.0, 0.0, 0.0 )

		else
			--Reset particle
			--if it is breaking... count the time then make it back...
			--SIEMPRE SE REARMA
			forming_timer = 0.0
			breaking = false
		end

		obj["rotation_v"] = rotation_v
		obj["forming_timer"] = forming_timer
		obj["breaking"] = breaking
		svgparticulas[i+1] = obj

	else
		this:UpdateParticlePosition( i, -10.0, -10.0, 0.0 )
	end

end


--nparts: cantidad de particulas
--nfeats: cantidad maxima de marcas sensadas
--nvalids: cantidad marcas sensadas

nfeats = 0
nvalids = 0

features = {}
moving = false
n_in_motions = 0
in_motions = {}

function this.Update( this )

	if (tindex>-1) then

		nfeats = this:GetTrackerFeaturesCount(tindex)
		nvalids = this:GetTrackerValidFeatures(tindex)

		if (dif>0) then
			--this:PushDebugString(" features: "..nvalids.."/"..nfeats )
		end

		features = {}
		g_speed_reaction = particlessvg["speed_reaction"]
		n_in_motions = 0
		in_motions = {}

		if (nfeats>0) then
			for f=0,nfeats-1  do
				x,y,val,vx,vy,trx,try = this:GetTrackerFeature( tindex, f )

				--vnorm = math.sqrt(vx*vx+vy*vy)

				x = -1*(-(x - 0.5)*15 + 0.0)
				y = (-(y - 0.5)*15 - 0.0)

				--if (val and vnorm>g_speed_reaction.value ) then
				if (val) then
					--features[f+1] = { x= x, y=y, val= val, vx=vx, vy=vy, trx=trx, try=try, vnorm=vnorm  }
					n_in_motions = n_in_motions + 1
					in_motions[n_in_motions] = { x= x, y=y, val= val, vx=vx, vy=vy, trx=trx, try=try, vnorm=vnorm  }
				end

			end
		end

		g_motion_sensitivity = particlessvg["motion_sensitivity"]
		g_motion_sight = particlessvg["motion_sight"]

		if ( n_in_motions > g_motion_sensitivity.value ) then
			--this:PushDebugString("IN MOTION!!!" )
		else
			if (dif>0) then
				--this:PushDebugString("waiting for gestures..." )
			end
		end

	end

	nparticulas = this:GetParticleCount()
	dt = this:GetDelta()


	for key,val in pairs(particlessvg) do
		val.value = this:GetInletData( val.index )
		--this:PushDebugString(key..": "..index.." value: "..value)
		particlessvg[key] = val
	end


	dt_local = dt * 1666.0  --reconvierte a milisegundos

	if (actual_age < 10 ) then
		ticks_local = actual_age
		grupos_reseted = false --Forzamos el reset...
		ResetGrupos(this)
	end


end

function this.Draw(this)
	if (tindex>-1) then

		nfeats = this:GetTrackerFeaturesCount(tindex)
		if (nfeats>0) then
				for f=0,nfeats-1  do

					x,y,val,vx,vy,trx,try = this:GetTrackerFeature( tindex, f )
					x = -(x - 0.5)*15 + 1.0
					y = -(y - 0.5)*15 - 1.1
					if (val) then
						luap5:stroke( 1.0, 1.0, 1.0, 1.0 )
						luap5:strokeWeight( 2.0 )
						--luap5:fill(1.0, 1.0, 1.0, 1.0 )

						luap5:line( x, y, x+0.1, y+0.1 )
					end
				end

				this:PushDebugString("luascript nfeats:"..nfeats);
		end
	end
end


function this.Finish(this)
    --this:PushDebugString("Hello from Finish")
end
