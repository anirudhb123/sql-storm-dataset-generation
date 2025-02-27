
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
), PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.CommentCount,
        COALESCE(UR.DisplayName, 'Anonymous') AS OwnerName,
        UR.Reputation AS OwnerReputation,
        R.ReputationRank
    FROM 
        RecentPosts RP
    LEFT JOIN 
        Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN 
        UserReputation UR ON U.Id = UR.UserId
    JOIN 
        (SELECT DISTINCT UserId, ReputationRank FROM UserReputation WHERE ReputationRank <= 10) R ON U.Id = R.UserId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.CommentCount,
    PD.OwnerName,
    PD.OwnerReputation,
    PD.ReputationRank,
    CASE 
        WHEN PD.Score > 0 THEN 'High'
        WHEN PD.Score = 0 THEN 'Neutral'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    PostDetails PD
WHERE 
    PD.CommentCount > 5
ORDER BY 
    PD.Score DESC, PD.CreationDate DESC
LIMIT 10;
