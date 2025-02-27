WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistoryWithDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        php.Name AS PostHistoryTypeName,
        CASE 
            WHEN ph.Comment IS NOT NULL THEN 'Comment: ' || ph.Comment
            ELSE 'No Comment'
        END AS CommentDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes php ON ph.PostHistoryTypeId = php.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.CommentCount,
    rp.Rank,
    ph.PostHistoryTypeName,
    ph.CommentDetails,
    COALESCE(us.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(us.TotalBounty, 0) AS UserTotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryWithDetails ph ON rp.PostId = ph.PostId
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    ph.PostHistoryTypeId IS NOT NULL 
    OR rp.Rank <= 5
ORDER BY 
    rp.Rank, rp.ViewCount DESC;

WITH RecursiveCTE AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursiveCTE r ON p.ParentId = r.Id
)
SELECT 
    rc.Title,
    rc.CreationDate,
    rc.Level,
    COUNT(c.Id) AS CommentCount
FROM 
    RecursiveCTE rc
LEFT JOIN 
    Comments c ON rc.Id = c.PostId
GROUP BY 
    rc.Id, rc.Title, rc.CreationDate, rc.Level
HAVING 
    COUNT(c.Id) > 0;
