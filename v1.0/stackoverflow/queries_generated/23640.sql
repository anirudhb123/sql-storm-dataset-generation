WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
BadgesPerUser AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    u.DisplayName,
    u.Reputation,
    u.ReputationRank,
    b.BadgeCount,
    b.HighestBadgeClass,
    ph.HistoryTypes,
    CASE 
        WHEN rp.RN = 1 THEN 'Latest Post by User'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    BadgesPerUser b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    (b.BadgeCount IS NULL OR b.BadgeCount > 5) 
    AND u.Reputation >= 100
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 50;

This query consists of multiple common table expressions (CTEs) to break down complex logic, including ranking users by reputation, counting badges per user, aggregating post history information, and ranking posts by user with specified criteria. It encompasses various SQL elements such as joins, aggregates, window functions, and conditional logic.
