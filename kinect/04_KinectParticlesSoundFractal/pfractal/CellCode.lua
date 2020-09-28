moldeolua = ""
moldeolua = ConsoleDataPath.."/puniverso/moldeo.lua"
dofile (moldeolua)

poemas_folder = ConsoleDataPath.."/poemas/"
lineas_poema = {}
caracteres_poema = {}
w = 128
h = 128

local milis = -1
local seconds = -1

function this.Init(this)

    this:PushDebugString("Hello from PUNIVERSO fractal script")
    milis = this:GetInletIndex("milliseconds")
    seconds = this:GetInletIndex("seconds")

--[[
    poemas_folder_amor = poemas_folder.."todo_era_amor.txt"
    --poemas_folder_amor = poemas_folder.."prueba.txt"
    this:PushDebugString("Abriendo poema: "..poemas_folder_amor)
    lineas_poema = lines_from(poemas_folder_amor)

    local fileContent = read_file(poemas_folder_amor);
    --print (fileContent);
    local imem = 0;
    local ip = 0;
    local jp = 0;
    local letras_usadas = {};

    if lineas_poema then
      for k,v in pairs(lineas_poema) do
        --this:PushDebugString("k:"..k.." v:"..v)
        for ck=1, v:len() do
          --caracteres_poema
          cv = string.upper(v:sub(ck,ck))
          cvb = cv:byte()

          base = 0
          top = 0
          if ( cvb>=48 and cvb<=57 ) then
            --NUMBERS
            --0123456789
            base = 0
            cvb = cvb - 48;
            top = (57 - 48) + 1
          elseif ( cvb>=65 and cvb<=90  ) then
            --CAPITAL LETTERS
            --ABSCDEFGHIJKLMNOPQRSTUVWXYZ
            base = 10
            cvb =  base + (cvb - 65);
            top = 36
          elseif ( cvb>=58 and cvb<=64  ) then
            --:;<=>?@
            base = 36
            cvb =  base + (cvb - 58);
            top = 7 + base
          elseif ( cvb>=32 and cvb<=47  ) then
            -- !"#$%&'()*+,-./
            base = 43
            cvb =  base + (cvb - 32);
            top = 16 + base
          elseif ( cvb==161  ) then
            --¡
            cvb =  59;
          elseif ( cvb>191  ) then
            --¿
            cvb =  60;
          elseif ( cvb>=91 and cvb<=96  ) then
            --
            cvb =  60;
          end

          if (cv and cvb<61) then
            --f_val = 1.0*cvb*0.00001
            jp = math.floor( imem / w );
            ip = math.floor( imem - jp*w );

            f_val = cvb
            letras_usadas[cv] = true
            this:PushDebugString("ck:"..ck.." cv:"..cv.." cvb:"..cvb.." f_val:"..f_val)
            this:WriteMemory( imem, 0, f_val )
            imem = imem + 1
          end
        end
      end
    end
    --]]
    this:WriteMemory( imem, 0, f_val )

    this:LoadMemory()

    this:DumpMemory( 0 )
    this:DumpMemory( 1 )
    this:DumpMemory( 2 )


    -->> Cell Programming is a state machine conditioner
    -->> now we inform the state machine we are beginning Program of our First Root Cell (index: 0) (return 1 if it'ok!)

    bp = this:CellBeginProgram(0)
    -->> If cell program has beginned, set the specific cell state machine
    if (bp) then
      -->> Set the delta aging (will be added at each iteration)
      this:CellAge(0.003)
      -->> Set the cloning age, after what it will call the Mutation machine. (will be added at each iteration)
      this:CellDuplicate(0.13)
      -->> Set the mutation state condition
      --this:CmpMemory( 0, 0, ">=", 0.4)
      -->> Then new cell created will take this id_cell code as mutation
      -- 0 this cell, 0 randomness is exact copy, 1.0 is random new code
      --this:CellMutate( 0, 0 )
      --this:CellCrossover( 0.0, 0.0 )
      -->> Set dying max age
      this:CellDie( 0.97 )
    end
    this:CellEndProgram()
    this:CellDumpProgram(0)

    bp = this:CellBeginProgram(1)
    if (bp) then
      this:CellAge(0.007)
      this:CellDuplicate(0.27)
    end
    this:CellEndProgram()
    this:CellDumpProgram(1)
--[[
    bp = this:CellBeginProgram(1)
    if (bp) then
      this:CellAge(0.003)
      this:CellDuplicate(0.53)
      this:CellDie( 0.97 )
    end
    this:CellEndProgram()
--]]
end


function this.Run(this)
  vmilis = "undefined"
  if (milis>-1) then
    vmilis = this:GetInletData(milis)
  end
  if (seconds>-1) then
    olds = vseconds
    vseconds = math.floor(this:GetInletData(seconds))
  end

  if not ( olds == vseconds) then
    this:PushDebugString("Run vmilis:"..vseconds)
  end
  --if lineas_poema then
    --this:PushDebugString("linea 1:"..lineas_poema[1])
  --end
  --this:CellDumpProgram(0)
  --this:CellDumpProgram(1)
  --this:CellDumpProgram(1)
  if (vseconds == 10) then
    this:CellDumpProgram(0)
    this:CellDumpProgram(1)
    this:CellDumpProgram(2)
    this:CellDumpProgram(3)
  end
end
