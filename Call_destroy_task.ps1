$body = @{
 "event_type"="do-something"
} | ConvertTo-Json

$header = @{
 "Accept"="application/vnd.github.everest-preview+json"
 "Authorization"="token e24b4a689f33e7898018c071e488b3578d2f167b"
} 

Invoke-RestMethod -Uri "https://api.github.com/repos/evry-ace/devops-training-team1/dispatches" -Method 'Post' -Body $body -Headers $header | ConvertTo-HTML
