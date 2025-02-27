WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        CAST(NULL AS INT) AS ParentId
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        rp.PostId AS ParentId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
),

UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        TRIM(tag.TagName) AS TagName, 
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><') AS tag(TagName)
    GROUP BY 
        tag.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalComments,
    us.TotalViews,
    us.TotalScore,
    pt.TagName
FROM 
    UserStats us
LEFT JOIN 
    PopularTags pt ON us.TotalPosts > 0
ORDER BY 
    us.TotalScore DESC, us.TotalPosts DESC
LIMIT 20;

-- performance benchmarking
ANALYZE RecursivePosts;
ANALYZE UserStats;
ANALYZE PopularTags;
