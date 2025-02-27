WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 1000
    AND rp.PostRank <= 5
ORDER BY 
    us.Reputation DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    'Total' AS DisplayName,
    NULL AS Reputation,
    SUM(GoldBadges) AS GoldBadges,
    SUM(SilverBadges) AS SilverBadges,
    SUM(BronzeBadges) AS BronzeBadges,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS AnswerCount,
    SUM(CommentCount) AS TotalComments,
    'Aggregate' AS PostCategory
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 1000;
