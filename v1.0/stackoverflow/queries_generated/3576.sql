WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswer
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostScores AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        UR.ReputationRank,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes
    FROM 
        RecentPosts RP
    LEFT JOIN 
        UserReputation UR ON UR.UserId = RP.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON V.PostId = RP.PostId
),
ClosedDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.Text,
        P.Title
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.ReputationRank,
    PS.UpVotes,
    PS.DownVotes,
    COALESCE(CD.Comment, 'Not Closed') AS CloseComment,
    COALESCE(CD.CreationDate, PS.CreationDate) AS LastActivity,
    CASE 
        WHEN PS.ViewCount > 100 THEN 'High Activity' 
        ELSE 'Low Activity' 
    END AS ActivityLevel
FROM 
    PostScores PS
LEFT JOIN 
    ClosedDetails CD ON CD.PostId = PS.PostId
ORDER BY 
    PS.ReputationRank
LIMIT 100;
