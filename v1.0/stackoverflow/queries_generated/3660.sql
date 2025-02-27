WITH UserReputation AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(AC.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts AC ON P.AcceptedAnswerId = AC.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year'
),
VoteSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        P.Id
)
SELECT 
    UR.DisplayName AS UserName,
    UR.Reputation,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    VU.UpVotes,
    VU.DownVotes,
    (CASE 
         WHEN VU.UpVotes + VU.DownVotes > 0 
         THEN (VU.UpVotes::float / (VU.UpVotes + VU.DownVotes)) * 100 
         ELSE NULL 
     END) AS UpVotePercentage,
    (CASE 
         WHEN PD.AcceptedAnswerId IS NOT NULL 
         THEN 'Yes'
         ELSE 'No'
     END) AS HasAcceptedAnswer
FROM 
    UserReputation UR
JOIN 
    PostDetails PD ON UR.Id = PD.OwnerUserId
LEFT JOIN 
    VoteSummary VU ON PD.PostId = VU.PostId
WHERE 
    UR.Rank <= 100
ORDER BY 
    UR.Reputation DESC, PD.ViewCount DESC
LIMIT 50;
