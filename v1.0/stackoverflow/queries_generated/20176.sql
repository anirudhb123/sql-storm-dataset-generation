WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(*) OVER (PARTITION BY pt.Name) AS TotalCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '365 days'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosedPosts,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenedPosts,
        COUNT(DISTINCT ph.PostId) AS TotalHistoryActions
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopTags AS (
    SELECT 
        tag.TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts p
    JOIN 
        Tags tag ON p.Tags LIKE CONCAT('%<', tag.TagName, '>%' )
    GROUP BY 
        tag.TagName
    HAVING 
        COUNT(*) > 10
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS Author,
    ua.TotalBounty,
    ua.ClosedPosts,
    ua.ReopenedPosts,
    tt.TagName,
    tt.TagUsage
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId IN (SELECT PostId FROM Comments WHERE UserId = u.Id)
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%<', tt.TagName, '>%' )
WHERE 
    rp.RankByScore < 10 -- Getting top 10 posts per type
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 100
UNION ALL
SELECT 
    NULL AS PostId,
    'Aggregate Bounty Data' AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    SUM(ua.TotalBounty) AS Score,
    NULL AS Author,
    NULL AS TotalBounty,
    SUM(ua.ClosedPosts) AS ClosedPosts,
    SUM(ua.ReopenedPosts) AS ReopenedPosts,
    NULL AS TagName,
    NULL AS TagUsage
FROM 
    UserActivity ua
WHERE 
    ua.TotalHistoryActions > 5
GROUP BY 
    ua.UserId
ORDER BY 
    Score DESC;
