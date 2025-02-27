WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(NULLIF(p.Title, ''), 'Untitled') AS SafeTitle
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),

ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.SafeTitle,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ur.Reputation,
    ur.BadgeCount,
    COALESCE(cp.CloseCount, 0) AS TotalCloseCount,
    COALESCE(cp.LastClosedDate, 'No closures') AS LastClosed
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.Score DESC, ur.Reputation DESC
LIMIT 10;

WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Id, 
        TagName, 
        1 AS Depth
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0
    UNION ALL
    SELECT 
        t.Id, 
        t.TagName, 
        th.Depth + 1
    FROM 
        Tags t
    JOIN 
        TagHierarchy th ON t.ExcerptPostId = th.Id
)

SELECT 
    th.TagName,
    COUNT(p.Id) AS PostCount
FROM 
    TagHierarchy th
LEFT JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', th.TagName, '%')
GROUP BY 
    th.TagName
HAVING 
    COUNT(p.Id) > 5
ORDER BY 
    PostCount DESC;
