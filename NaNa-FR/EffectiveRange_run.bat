set indir=".\EffectiveRange_Input\"
set outdir=".\EffectiveRange_Output\"
for /R %indir% %%f in (*.txt) do (
    molscat-Na2 < %%f > %outdir%%%~nxf
)
pause