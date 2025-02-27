-- Performance Benchmarking Query
-- This query retrieves aggregated statistics for posts, users, and their interactions.

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueOwners
    FROM Posts p
    GROUP BY p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Votes v
    GROUP BY v.PostId
)

SELECT 
    ps.PostTypeId,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews,
    ps.UniqueOwners,
    us.UserId,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.AverageReputation,
    vs.TotalVotes,
    vs.TotalUpVotes AS PostTotalUpVotes,
    vs.TotalDownVotes AS PostTotalDownVotes
FROM PostStats ps
JOIN UserStats us ON us.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = ps.PostTypeId)
LEFT JOIN VoteStats vs ON vs.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = ps.PostTypeId)
ORDER BY ps.PostTypeId, us.UserId;
