-- Performance benchmarking query to check user activity, post activity, and badge counts
WITH UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostTypeCounts AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Id, pt.Name
),
OverallStats AS (
    SELECT 
        COUNT(DISTINCT u.Id) AS TotalUsers,
        SUM(COALESCE(u.PostCount, 0)) AS TotalPosts,
        SUM(COALESCE(u.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(u.BadgeCount, 0)) AS TotalBadges,
        SUM(COALESCE(u.TotalViews, 0)) AS TotalViews,
        SUM(COALESCE(u.TotalScore, 0)) AS TotalScore
    FROM 
        UserPostActivity u
)
SELECT 
    o.TotalUsers,
    o.TotalPosts,
    o.TotalComments,
    o.TotalBadges,
    o.TotalViews,
    o.TotalScore,
    pt.PostTypeId,
    pt.PostTypeName,
    pt.PostCount
FROM 
    OverallStats o
CROSS JOIN 
    PostTypeCounts pt
ORDER BY 
    pt.PostCount DESC;
