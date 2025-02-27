WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        COALESCE(H.Edits, 0) AS EditCount,
        COALESCE(C.Count, 0) AS CommentCount
    FROM Posts P
    LEFT JOIN ( 
        SELECT 
            PostId,
            COUNT(*) AS Edits
        FROM PostHistory
        WHERE PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY PostId
    ) H ON P.Id = H.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
), RankedUsers AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.Reputation, 
        us.Upvotes, 
        us.Downvotes, 
        us.TotalPosts, 
        us.TotalComments, 
        us.TotalBadges,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM UserStats us
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.Upvotes,
    ru.Downvotes,
    ru.TotalPosts,
    ru.TotalComments,
    ru.TotalBadges,
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.LastActivityDate,
    pa.Score,
    pa.EditCount,
    pa.CommentCount
FROM RankedUsers ru
LEFT JOIN PostActivity pa ON ru.UserId = pa.PostId
WHERE ru.UserRank <= 10
ORDER BY ru.UserRank, pa.Score DESC;
