WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(COALESCE(VoteTypeId, 0)) AS MaxVoteTypeId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
),
AggregatedPostActivity AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.OwnerName,
        RP.CommentCount,
        CASE 
            WHEN RP.Score > 10 THEN 'High'
            WHEN RP.Score BETWEEN 1 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory,
        COUNT(PH.Id) AS PostHistoryCount
    FROM 
        RecentPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.OwnerName, RP.CommentCount
),
RankedPosts AS (
    SELECT 
        AP.*,
        R.ReputationRank
    FROM 
        AggregatedPostActivity AP
    JOIN 
        UserReputation R ON AP.OwnerName = R.DisplayName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ScoreCategory,
    RP.CommentCount,
    RP.ReputationRank
FROM 
    RankedPosts RP
WHERE 
    RP.ReputationRank <= 10
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC
LIMIT 50;
