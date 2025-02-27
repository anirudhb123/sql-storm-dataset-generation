-- Performance Benchmarking SQL Query
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(b.Id IS NOT NULL) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY (string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        t.TagName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalBadges,
    ps.PostTypeId,
    ps.PostCount,
    ps.TotalScore,
    ps.AvgViewCount,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON true
JOIN 
    TagStatistics ts ON true
ORDER BY 
    ua.TotalPosts DESC, ua.TotalUpVotes DESC;
