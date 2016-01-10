utils={}

function utils.dir()
  l = file.list();
  for k,v in pairs(l) do
    print(k.."\t"..v)
  end
end

function utils.factoryreset()
  -- delete files?
  -- reset wifi
  node.restore()
  node.restart()
end

function utils.file_exists(name)
  f=file.open(name,"r")
  if (f==nil) then
    return false
  else
    file.close(f)
    return true
  end
end

function utils.dofile(name)
  if utils.file_exists(name..".lc") then
    dofile(name..".lc")
  else
    dofile(name..".lua")
  end
end
