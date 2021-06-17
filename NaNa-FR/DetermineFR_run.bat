set indir=".\DetermineFR_Input\"
set outdir=".\DetermineFR_Output\"
for /R %indir% %%f in (*.txt) do (
    molscat-Na2 < %%f > %outdir%%%~nxf
)
pause