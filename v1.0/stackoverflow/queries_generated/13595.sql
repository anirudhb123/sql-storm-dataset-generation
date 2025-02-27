-- Performance Benchmarking Query
WITH PostMetrics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Votes.Id) AS TotalVotes,
        AVG(Votes.CreationDate) AS AverageVoteDate
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AvgPostScore
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id
)
SELECT 
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.TotalComments,
    P.TotalVotes,
    P.AverageVoteDate,
    U.UserId,
    U.DisplayName,
    U.PostsCreated,
    U.TotalViews,
    U.AvgPostScore
FROM 
    PostMetrics P
JOIN 
    UserEngagement U ON P.PostId = U.UserId
ORDER BY 
    P.ViewCount DESC
LIMIT 100;
