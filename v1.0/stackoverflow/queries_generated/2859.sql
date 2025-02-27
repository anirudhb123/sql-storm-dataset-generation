WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS RankByUpvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId IN (SELECT Id FROM Posts)
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT * 
    FROM UserActivity
    WHERE RankByUpvotes <= 10
),
PostWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownvoteCount
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '6 months'
    ORDER BY P.CreationDate DESC
    LIMIT 100
)
SELECT 
    U.DisplayName AS TopUser,
    UA.Upvotes,
    UA.Downvotes,
    PWC.Title AS PostTitle,
    PWC.CreationDate AS PostDate,
    PWC.Score AS PostScore,
    PWC.ViewCount AS PostViews,
    PWC.CommentCount AS PostComments,
    PWC.UpvoteCount AS PostUpvotes,
    PWC.DownvoteCount AS PostDownvotes
FROM TopUsers UA
JOIN PostWithComments PWC ON PWC.PostId IN (
    SELECT PostId 
    FROM Votes V 
    WHERE V.UserId = UA.UserId 
    AND V.VoteTypeId = 2
)
ORDER BY UA.Upvotes DESC, PWC.Score DESC;
