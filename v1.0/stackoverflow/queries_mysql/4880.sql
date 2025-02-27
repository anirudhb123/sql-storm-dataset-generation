
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pt.Tag,
    pt.TagCount
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.RankByScore <= 3
LEFT JOIN 
    PopularTags pt ON FIND_IN_SET(pt.Tag, REPLACE(REPLACE(rp.Tags, '>', ''), '<', '')) > 0
WHERE 
    us.Reputation >= (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    us.Reputation DESC, 
    rp.Score DESC
LIMIT 100;
