WITH RecursiveTagHierarchy AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        0 AS Depth
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        r.Depth + 1
    FROM 
        Tags t
    JOIN 
        RecursiveTagHierarchy r ON t.Id = r.TagId
), 

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),

ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        p.OwnerUserId
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ur.PostCount,
    ur.PositivePosts,
    ur.NegativePosts,
    p.Title,
    p.ViewCount,
    p.CreationDate,
    COALESCE(bt.Name, 'No Badge') AS TopBadge,
    COALESCE(tt.TagName, 'No Tags') AS PrimaryTag
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ActivePosts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges bt ON u.Id = bt.UserId AND bt.Class = 1 -- Gold badges
LEFT JOIN 
    (SELECT 
        p.Id,
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS TagName
     FROM 
        Posts p WHERE p.Tags IS NOT NULL) AS tt ON p.Id = tt.Id
WHERE 
    ur.Reputation > 1000
    AND ur.PostCount > 5
    AND p.ViewCount IS NOT NULL
ORDER BY 
    u.Reputation DESC, p.ViewCount DESC;

The query constructs include:

- **CTEs**: `RecursiveTagHierarchy`, `UserReputation`, and `ActivePosts` for hierarchical data manipulation and summarizing user and post metrics.
- **Window Functions**: `DENSE_RANK()` to assign a rank based on the number of views for active posts.
- **LEFT JOINs**: To get additional data like badges and tags.
- **COALESCE**: To replace NULL values with 'No Badge' or 'No Tags'.
- **Complicated predicates**: Filtering users by reputation and post count.
- **String manipulation**: Parsing Tags from posts with `UNNEST` and `STRING_TO_ARRAY`.
- **NULL logic**: Handling cases where some users may not have associated badges or tags.
