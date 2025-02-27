WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PH.CreationDate DESC) AS ActivityRank,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.LastAccessDate
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.LastAccessDate,
    R.PostId, 
    R.Title,
    R.CreationDate AS PostCreationDate,
    R.Score,
    R.ViewCount,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.PostId = R.PostId) AS CommentCount,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     WHERE R.PostId IN (SELECT P.Id FROM Posts P WHERE P.Tags LIKE '%' || T.TagName || '%')) AS PostTags
FROM 
    UserActivity U
JOIN 
    RecentPosts R ON U.UserId = R.OwnerUserId
WHERE 
    U.ActivityRank = 1
    AND R.RecentPostRank <= 3
ORDER BY 
    U.Reputation DESC, R.CreationDate DESC
LIMIT 10;

-- Notes:
-- This query fetches the top users with a reputation above 1000 and their recent posts,
-- including the count of comments on each post and the associated tags. 
-- It limits the returned users to the top 10 based on their reputation. 
