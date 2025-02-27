-- Performance Benchmarking Query
WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(Id) AS TotalPosts,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        AVG(ViewCount) AS AverageViews,
        AVG(AnswerCount) AS AverageAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        Id AS UserId,
        COUNT(*) AS TotalPostsByUser,
        SUM(UPVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    pt.Name AS PostType,
    pc.TotalPosts,
    pc.PositiveScorePosts,
    pc.NegativeScorePosts,
    pc.AverageViews,
    pc.AverageAnswers,
    us.UserId,
    us.TotalPostsByUser,
    us.TotalUpVotes,
    us.TotalDownVotes,
    vc.TotalVotes,
    vc.UpVotes,
    vc.DownVotes
FROM 
    PostCounts pc
JOIN 
    PostTypes pt ON pc.PostTypeId = pt.Id
JOIN 
    UserStats us ON us.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts)
JOIN 
    VoteCounts vc ON vc.PostId IN (SELECT Id FROM Posts)
ORDER BY 
    pc.TotalPosts DESC;
