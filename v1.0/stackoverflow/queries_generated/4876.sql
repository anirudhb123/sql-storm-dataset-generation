WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(DISTINCT c.Id) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(b.Class = 1::smallint), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2::smallint), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3::smallint), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
RecentPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        ua.DisplayName,
        ua.TotalBounty,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId) 
    WHERE 
        rp.rn = 1 -- Get the most recent post for each user
)
SELECT 
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.AnswerCount,
    r.DisplayName,
    r.TotalBounty,
    r.GoldBadges,
    r.SilverBadges,
    r.BronzeBadges,
    CASE 
        WHEN r.Score > 100 THEN 'Highly Rated'
        WHEN r.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rating' 
    END AS PostRating
FROM 
    RecentPostStats r
WHERE 
    r.AnswerCount > 0 OR r.ViewCount > 500
ORDER BY 
    r.Score DESC, r.CreationDate ASC
LIMIT 100;
