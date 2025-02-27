WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Title,
    p.Body,
    u.DisplayName AS Owner,
    u.Reputation,
    ub.BadgeCount,
    pp.CommentCount,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount,
    COALESCE(cp.FirstClosedDate, 'No Closure') AS FirstClosedDate,
    CASE 
        WHEN cp.CloseVoteCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    p.Score,
    rp.PostRank
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostComments pp ON pp.PostId = p.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = p.Id
WHERE 
    (p.Score IS NULL OR p.Score > 5) 
    AND u.Reputation BETWEEN 100 AND 10000
ORDER BY 
    rp.PostRank, u.Reputation DESC
LIMIT 100;
