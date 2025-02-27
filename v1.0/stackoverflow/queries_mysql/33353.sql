
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    CROSS JOIN 
        (SELECT @row_number := 0, @current_user := '') AS vars
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN bp.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN bp.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN bp.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bp ON u.Id = bp.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpvoteCount
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 1000 
ORDER BY 
    us.Reputation DESC, 
    rp.Score DESC
LIMIT 10 OFFSET 0;
