WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS TotalComments
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    us.DisplayName AS OwnerName,
    us.Reputation AS OwnerReputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(pc.TotalComments, 0) AS TotalComments,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Recent'
        ELSE 'Earlier Post'
    END AS RecentClassification
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.CreationDate DESC
LIMIT 100
OFFSET 0;

-- Include the concept of NULL logic with a UNION for posts with no comments
UNION ALL
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    0 AS TotalComments,
    'No Comments' AS RecentClassification
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
WHERE 
    p.Id NOT IN (SELECT PostId FROM Comments)
AND 
    p.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  
