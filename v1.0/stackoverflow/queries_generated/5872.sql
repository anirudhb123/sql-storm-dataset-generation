WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 
                 WHEN V.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS Score,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS ClosureCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END), 0) AS DeletionCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
)
SELECT 
    UR.DisplayName AS UserName,
    UR.Score AS UserScore,
    P.Title,
    P.Score AS PostScore,
    P.CommentCount,
    P.ClosureCount,
    P.DeletionCount,
    P.CreationDate
FROM 
    UserReputation UR
JOIN 
    PostStatistics P ON UR.UserId = P.OwnerDisplayName
ORDER BY 
    UserScore DESC, PostScore DESC
LIMIT 100;
