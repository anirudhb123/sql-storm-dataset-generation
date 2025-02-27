
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(TAGS.TagName) AS TagCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        P.Title,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1) AS TagName, P.Id 
               FROM Posts P 
               JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                             SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1) AS TAGS 
    ON TAGS.Id = P.Id
    GROUP BY P.Id, P.OwnerUserId, P.Title
), 
PostHistoryDetails AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(DISTINCT PH.UserId) AS EditorsCount,
        GROUP_CONCAT(DISTINCT PH.UserDisplayName ORDER BY PH.UserDisplayName SEPARATOR ', ') AS Editors
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 11)  
    GROUP BY PH.PostId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.ReputationRank,
    PS.PostId,
    PS.Title,
    PS.TagCount,
    PS.CommentCount,
    PS.TotalBounty,
    PH.LastEditDate,
    PH.EditorsCount,
    PH.Editors
FROM UserReputation U
JOIN PostStatistics PS ON U.UserId = PS.OwnerUserId
LEFT JOIN PostHistoryDetails PH ON PS.PostId = PH.PostId
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND PS.TagCount > 3 
    AND PS.RecentPostRank = 1
ORDER BY U.Reputation DESC, PS.CommentCount DESC
LIMIT 50;
