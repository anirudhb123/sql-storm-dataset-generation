WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
        AND p.Score IS NOT NULL
), PopularPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerName,
        r.CreationDate,
        r.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    GROUP BY 
        r.PostId, r.Title, r.OwnerName, r.CreationDate, r.Score
    HAVING 
        COUNT(c.Id) > 5
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        CASE 
            WHEN u.Reputation > 10000 THEN 'Expert'
            WHEN u.Reputation BETWEEN 5000 AND 10000 THEN 'Experienced'
            ELSE 'Novice'
        END AS UserLevel
    FROM 
        Users u
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerName,
    pp.CreationDate,
    pp.Score,
    pp.CommentCount,
    ur.UserLevel
FROM 
    PopularPosts pp
JOIN 
    UserReputation ur ON pp.OwnerName = ur.UserId
LEFT JOIN 
    PostHistory ph ON pp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 -- Looking for closed posts
WHERE 
    ph.PostId IS NULL  -- Exclude closed posts
ORDER BY 
    pp.Score DESC
LIMIT 10;

-- Second query to find users with the most badges, ordered by reputation and filtered by badge type
WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), UserWithInfo AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        CASE 
            WHEN ub.BadgeCount >= 10 THEN 'Badge Collector'
            ELSE 'Regular User'
        END AS UserType
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    uwi.DisplayName,
    uwi.Reputation,
    uwi.BadgeCount,
    uwi.GoldBadges,
    uwi.SilverBadges,
    uwi.BronzeBadges,
    uwi.UserType
FROM 
    UserWithInfo uwi
WHERE 
    uwi.Reputation IS NOT NULL
ORDER BY 
    uwi.Reputation DESC, uwi.BadgeCount DESC
LIMIT 5;

-- Exploration of various join scenarios while handling potential NULL values
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(SUM(case when p.AcceptedAnswerId IS NOT NULL then 1 else 0 end), 0) AS AcceptedAnswers,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount,
    COALESCE(MAX(b.Date), 'No Badges') AS LatestBadgeDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalPosts DESC, AcceptedAnswers DESC;
