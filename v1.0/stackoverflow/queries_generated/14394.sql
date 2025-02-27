-- Performance Benchmarking Query
-- This query retrieves a summary of posts, including their vote counts, comments, and related badges for users,
-- along with the total number of users and posts in the system to gauge system performance.

WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS TotalVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = p.Id) AS TotalAnswers
    FROM 
        Posts p
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS TotalBadges
    FROM 
        Users u
)

-- Final Select to combine Post and User summaries
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TotalVotes,
    ps.TotalComments,
    ps.TotalAnswers,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts
FROM 
    PostSummary ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id  -- Joining with users to get owner information
JOIN 
    UserSummary us ON us.UserId = u.Id
ORDER BY 
    ps.CreationDate DESC
LIMIT 100;  -- Limiting the results for performance benchmarking
