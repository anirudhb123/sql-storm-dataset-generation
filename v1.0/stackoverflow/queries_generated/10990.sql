-- Performance Benchmarking Query
-- This query fetches aggregate statistics about posts, users, and votes to evaluate performance.
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        AVG(u.Reputation) AS AverageReputation,
        SUM(u.Views) AS TotalUserViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
VoteStats AS (
    SELECT 
        v.VoteTypeId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS UpVotesAndCloseVotes
    FROM 
        Votes v
    GROUP BY 
        v.VoteTypeId
)
SELECT 
    pts.PostTypeId,
    pts.TotalPosts,
    pts.PositiveScorePosts,
    pts.TotalViews,
    pts.AverageScore,
    pts.UniqueAuthors,
    us.AverageReputation,
    us.TotalUserViews,
    vs.TotalVotes,
    vs.UpVotesAndCloseVotes
FROM 
    PostStats pts
JOIN 
    UserStats us ON 1=1 -- Cross join for overall user stats (or you can refine this as needed)
JOIN 
    VoteStats vs ON 1=1 -- Cross join for overall vote stats (or you can refine this as needed)
ORDER BY 
    pts.PostTypeId;
