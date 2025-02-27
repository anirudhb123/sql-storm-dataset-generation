-- Performance benchmarking query to analyze post statistics and user contributions
WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.CommentCount,
        COUNT(Comments.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Posts.CreationDate >= '2020-01-01' -- Filter for posts created since 2020
    GROUP BY 
        Posts.Id
),
UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(Posts.Score) AS TotalScore,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers,
        SUM(Posts.CommentCount) AS TotalComments
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.TotalComments,
    ps.UpVotes,
    ps.DownVotes,
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    us.TotalViews,
    us.TotalAnswers,
    us.TotalComments
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId IN (SELECT AcceptedAnswerId FROM Posts) -- Filter for posts with accepted answers
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC; -- Order by post score and view count
