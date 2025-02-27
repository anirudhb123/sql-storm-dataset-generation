-- Performance Benchmarking Query

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
), PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(COALESCE(ps.ViewCount, 0)) AS AverageViews
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            Id, 
            ViewCount 
        FROM 
            Posts) ps ON ps.Id = p.Id
    GROUP BY 
        p.PostTypeId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.BadgeCount,
    tu.TagName,
    tu.PostCount AS TagPostCount,
    tu.TotalViews AS TagTotalViews,
    ps.PostTypeId,
    ps.TotalPosts,
    ps.AverageScore,
    ps.AverageViews
FROM 
    UserActivity ua
LEFT JOIN 
    TagUsage tu ON ua.PostCount > 0
LEFT JOIN 
    PostStatistics ps ON ps.TotalPosts > 0
ORDER BY 
    ua.PostCount DESC, ua.UpVotes DESC;
