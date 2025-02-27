
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
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
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
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
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
    PopularTags pt ON rp.Tags LIKE '%' + pt.Tag + '%'
WHERE 
    us.Reputation >= (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    us.Reputation DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
