param(
  [string]
  $pat=$env:JIRAPAT,
  [string]
  $deployment="deployname",
  [string]
  $head,
  [string]
  $base,
  [string]
  $baseurl,
  [string]
  $creator
)
$api = "/rest/api/2/"
$uri = $baseurl + $api
$user = $pat
$ah = @{
  'Authorization' = $user
  #'Content-Type'= 'application/json'
} 
# --------------------
# Get user id
# --------------------

$api = "/rest/api/3/user/search?query=$($creator)"
$uri = $baseurl + $api
$u = Invoke-RestMethod -Method Get -Uri $uri -Headers $ah -ContentType "application/json"
$Approver_accountid=$u.accountId
$Creator_accountid=$u.accountId
$Tester_accountid=$u.accountId
$Reporter_accountid=$u.accountId
$Deployer_accountid=$u.accountId

# --------------------
# Post for new Change.
# --------------------
$projectkey = "CS"
# Change request details
$ps = get-date -AsUTC
$pe = $ps.AddMinutes(30)

$changedata = @{
  fields = @{reporter = @{accountId = "$($Reporter_accountid)"}
    issuetype         = @{id = "10118" }
    customfield_10271 = "Github action"
    project           = @{
      key = $projectkey 
    }
    customfield_10262 = @{
      self  = $baseurl+"/rest/api/3/customFieldOption/10689"
      value = "Prod"
      id    = "10689"
    }
    description       = @{
      type    = "doc"
      version = 1
      content = @(@{
        type    = "paragraph"
        content = @(@{
          type = "text"
          text = "Github action created this: $($deployment),Head:$($head),Base:$($base)"
        })
      })
    }
    customfield_10010 = "69"
    customfield_10256 = @{
      type    = "doc"
      version = 1
      content = @( @{
        type    = "paragraph"
        content = @(@{
          type = "text"
          text = "Test rollback plan"
        })
      })
    }
    customfield_10247 = $pe
    summary           = "Called from GHA $(get-date)"
    customfield_10246 = $ps
  }
}

$changeDataJson=$changedata | ConvertTo-Json -Depth 10
$api = "/rest/api/3/issue"
$uri = $baseurl + $api
$k = Invoke-RestMethod -Method Post -Uri $uri -Headers $ah -ContentType "application/json" -Body $changeDataJson
if($k){

$Case=$k.key
$CaseID=$k.id
$caseLink=$k.self
# ------------------
# Get transissions
# ------------------
$api = "/rest/api/3/issue/$case/transitions"
$uri = $baseurl + $api
$t = Invoke-RestMethod -Method Get -Uri $uri -Headers $ah -ContentType "application/json"

$close=$t.transitions | Where-Object{$_.name -eq "Close"}

# -------------------- 
# Transision to closed
# --------------------

$transitiondata= @{
  fields= @{
    customfield_10261 = @{value = "Successful"} # Result "Fail"
  }
  transition=@{
    id = $($close.id)
  }
}
$transitiondataJson=$transitiondata|ConvertTo-Json -Depth 10
$api = "/rest/api/3/issue/$case/transitions"
$uri = $baseurl + $api
$t = Invoke-RestMethod -Method Post -Uri $uri -Headers $ah -ContentType "application/json" -Body $transitiondataJson
}

