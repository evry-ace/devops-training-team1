$body = @{
 "event_type"="do-something"
} | ConvertTo-Json

$header = @{
 "Accept"="application/vnd.github.everest-preview+json"
 "Authorization"="token 399b25839157d8420298bd4328cd5745fb81ba60"
} 

Invoke-RestMethod -Uri "https://api.github.com/repos/evry-ace/devops-training-team1/dispatches" -Method 'Post' -Body $body -Headers $header | ConvertTo-HTML
