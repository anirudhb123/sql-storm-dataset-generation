WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY U.Id
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(CAL.AverageScore, 0) AS AverageScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            AVG(Score) AS AverageScore 
        FROM Posts 
        GROUP BY PostId
    ) CAL ON P.Id = CAL.PostId
) 
SELECT 
    UR.UserId, 
    UR.DisplayName,
    UR.Reputation,
    UR.PostCount,
    UR.TotalBounties,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AverageScore,
    PS.RecentPostRank,
    CASE 
        WHEN PS.RecentPostRank = 1 THEN 'Most Recent'
        ELSE NULL 
    END AS PostStatus
FROM UserReputation UR
LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerDisplayName
WHERE UR.Reputation > 1000 
AND (PS.Score IS NULL OR PS.Score > 10)
ORDER BY UR.Reputation DESC, PS.CreationDate
FETCH FIRST 10 ROWS ONLY;
