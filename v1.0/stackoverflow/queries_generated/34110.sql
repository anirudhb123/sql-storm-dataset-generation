WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId, 0)) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, UNNEST(NULLIF(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags)-2), ''))::text[]) AS TagName FROM Posts) t ON p.Id = t.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    COALESCE(u.PostCount, 0) AS UserPostCount,
    COALESCE(u.TotalScore, 0) AS UserTotalScore,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags
FROM 
    PostHierarchy ph
LEFT JOIN 
    UserStats u ON u.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN 
    RecentPostStats rp ON rp.PostId = ph.PostId
ORDER BY 
    ph.Level, rp.VoteCount DESC;

