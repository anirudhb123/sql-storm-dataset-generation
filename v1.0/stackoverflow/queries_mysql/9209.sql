
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        Upvotes,
        Downvotes,
        PostCount,
        CommentCount,
        BadgeCount,
        @rank := @rank + 1 AS ReputationRank
    FROM 
        UserStats, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.CommentCount,
    TU.Upvotes,
    TU.Downvotes,
    TU.BadgeCount,
    (SELECT GROUP_CONCAT(DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) SEPARATOR ', ') 
     FROM 
     (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
      SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS numbers 
     WHERE numbers.n <= LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, ',', '')) + 1 AND P.OwnerUserId = TU.UserId) AS AssociatedTags
FROM 
    TopUsers TU
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC;
