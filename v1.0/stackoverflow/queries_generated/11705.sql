-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        Id AS UserId,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        AVG(Reputation) AS AverageReputation
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id
),
TagStats AS (
    SELECT 
        TagName,
        SUM(Count) AS TotalPosts,
        COUNT(DISTINCT ExcerptPostId) AS UniqueExcerptPosts,
        COUNT(DISTINCT WikiPostId) AS UniqueWikiPosts
    FROM Tags
    GROUP BY TagName
),
PostActivity AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Comments.CommentCount,
        COALESCE(CommentDetails.TotalComments, 0) AS TotalComments
    FROM Posts
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) AS CommentDetails ON Posts.Id = CommentDetails.PostId
)
SELECT 
    U.UserId,
    U.PostCount,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.AverageReputation,
    T.TagName,
    T.TotalPosts,
    T.UniqueExcerptPosts,
    T.UniqueWikiPosts,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.TotalComments
FROM UserStats U
JOIN TagStats T ON U.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts)
JOIN PostActivity P ON P.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.UserId)
ORDER BY U.PostCount DESC, U.AverageReputation DESC, P.Score DESC;
