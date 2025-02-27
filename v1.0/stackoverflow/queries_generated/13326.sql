-- Performance Benchmarking Query
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
)
SELECT 
    UM.UserId,
    UM.DisplayName,
    UM.Reputation,
    UM.TotalPosts,
    UM.TotalComments,
    PM.PostId,
    PM.Title,
    PM.CreationDate AS PostCreationDate,
    PM.Score,
    PM.ViewCount,
    PM.AnswerCount,
    PM.CommentCount AS PostCommentCount,
    PM.FavoriteCount,
    PM.LastActivityDate,
    UM.TotalUpVotes,
    UM.TotalDownVotes,
    UM.TotalBountyAmount
FROM UserMetrics UM
JOIN PostMetrics PM ON UM.UserId = PM.OwnerDisplayName -- Assuming OwnerDisplayName matches the User DisplayName
ORDER BY UM.Reputation DESC, PM.ViewCount DESC;
