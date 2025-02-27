WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagUsage
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    INNER JOIN 
        PostLinks pl ON pl.PostId = p.Id
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
)
SELECT 
    u.UserId,
    u.DisplayName,
    ups.PostCount,
    ups.AverageScore,
    ups.TotalViews,
    pp.Title AS RecentPostTitle,
    pp.CreationDate AS RecentPostDate,
    t.TagName AS PopularTag,
    t.TagUsage
FROM 
    UserPostStats ups
INNER JOIN 
    Users u ON ups.UserId = u.Id
LEFT JOIN 
    RecentPosts pp ON u.Id = pp.OwnerUserId AND pp.PostRank = 1
LEFT JOIN 
    PopularTags t ON t.TagName IN (SELECT UNNEST(STRING_TO_ARRAY((SELECT Tags FROM Posts WHERE OwnerUserId = u.Id ORDER BY CreationDate DESC LIMIT 1), ',')))
WHERE 
    ups.PostCount > 5
ORDER BY 
    ups.TotalViews DESC,
    ups.AverageScore DESC;
