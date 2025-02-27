WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN bh.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(uh.Upvotes, 0) AS Upvotes,
        COALESCE(uh.Downvotes, 0) AS Downvotes,
        COALESCE(ph.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UserActivity uh ON p.OwnerUserId = uh.UserId
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id
),
CombinedMetrics AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.Upvotes,
        pm.Downvotes,
        COALESCE(t.Tags, '{}') AS Tags,
        t.PostCount AS TopTagCount
    FROM 
        PostMetrics pm
    LEFT JOIN 
        (SELECT 
            TagName,
            COUNT(*) AS PostCount
         FROM 
            TopTags 
         GROUP BY 
            TagName
        ) t ON t.TagName = ANY(pm.Tags)
)
SELECT 
    cm.Title,
    cm.ViewCount,
    cm.Upvotes,
    cm.Downvotes,
    cm.TopTagCount
FROM 
    CombinedMetrics cm
WHERE 
    cm.ViewCount > 1000
ORDER BY 
    cm.Upvotes DESC, 
    cm.ViewCount DESC
LIMIT 10;
