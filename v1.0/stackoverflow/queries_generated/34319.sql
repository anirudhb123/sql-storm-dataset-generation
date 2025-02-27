WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        CAST(0 AS int) AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        COUNT(*) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    r.Level AS PostLevel,
    COALESCE(ps.UsageCount, 0) AS TagUsage,
    ph.ChangeCount AS RecentChanges,
    u.PostCount,
    u.CommentCount,
    u.TotalBounties
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
LEFT JOIN 
    UserActivity u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PopularTags ps ON p.Tags LIKE '%' || ps.TagName || '%'
LEFT JOIN 
    RecentPostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '90 days'
ORDER BY 
    p.CreationDate DESC,
    u.PostCount DESC;
