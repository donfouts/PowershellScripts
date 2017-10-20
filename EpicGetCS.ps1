,$ChangesetIDS = @(1956)
# 
$Repository = 'D:\Repositories\PHM_Epic\Main\*'
$EpicStage = 'D:\EpicStage\'

write-host "let's clean this up"

remove-item $EpicStage -Recurse -Force
New-Item 'D:\EpicStage\' -ItemType directory 

remove-item "$Repository" -Recurse -Force
#New-Item 'D:\Repositories\PHM_Epic\' -ItemType directory 

set-location D:\Repositories\PHM_Epic

write-host "getting change sets"


foreach($i in $ChangesetIDS){

& "tfpt.exe" "getcs" "/changeset:$i"

if($i -gt 1583){$Repository = 'D:\Repositories\PHM_Epic\Main\*'}ELSE{$Repository = 'D:\Repositories\PHM_Epic\*'}

cp $Repository $EpicStage -Recurse -Force -Verbose
if(Test-Path 'D:\EpicStage\$tf') {remove-item 'D:\EpicStage\$tf' -Recurse -Force}


}


