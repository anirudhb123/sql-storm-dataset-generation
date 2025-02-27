-- Performance Benchmarking SQL Query

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
VoteSummary AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        vt.Name
)

SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounties,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalBadges,
    ps.PostType,
    ps.PostCount,
    ps.AvgScore,
    ps.TotalViews,
    vs.VoteType,
    vs.VoteCount
FROM 
    UserActivity ua
FULL JOIN 
    PostStatistics ps ON ua.UserId IS NOT NULL
FULL JOIN 
    VoteSummary vs ON ps.PostType IS NOT NULL
ORDER BY 
    ua.TotalPosts DESC, ps.PostCount DESC, vs.VoteCount DESC;
