WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8) AS AvgBounty
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.CommentCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.AvgBounty
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.PostId = us.UserId
WHERE 
    rp.ScoreRank <= 3
    AND us.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY 
    us.Reputation DESC, rp.Score DESC
LIMIT 10;

SELECT DISTINCT 
    p.Id,
    p.Title,
    p.Score
FROM 
    Posts p
WHERE 
    p.Score > 10
UNION
SELECT 
    p2.Id,
    p2.Title,
    p2.Score
FROM 
    Posts p2
JOIN 
    PostHistory ph ON p2.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId = 10;

SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    Posts p
WHERE 
    EXTRACT(YEAR FROM p.CreationDate) = 2023
    OR (p.ClosedDate IS NOT NULL AND p.ClosedDate >= CURRENT_DATE - INTERVAL '30 days');
