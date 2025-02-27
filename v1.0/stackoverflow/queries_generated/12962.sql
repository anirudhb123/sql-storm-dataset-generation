-- Performance Benchmarking Query: Retrieve Statistics of Posts, Users, and Votes

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostsCreated,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.Id IS NOT NULL) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
VoteStats AS (
    SELECT 
        vt.Id AS VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        VoteTypes vt
    LEFT JOIN 
        Votes v ON vt.Id = v.VoteTypeId
    GROUP BY 
        vt.Id
)

SELECT 
    ps.PostTypeId,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    ps.AvgScore,
    ps.AvgViews,
    ps.LastPostDate,
    us.UserId,
    us.PostsCreated,
    us.TotalBounty,
    us.TotalVotes,
    vs.VoteTypeId,
    vs.VoteCount
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.PostsCreated > 0 -- To filter users who have created posts
JOIN 
    VoteStats vs ON vs.VoteCount > 0 -- To filter vote types that have been used
ORDER BY 
    ps.TotalPosts DESC, us.PostsCreated DESC, vs.VoteCount DESC;
