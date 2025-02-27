
WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
UserDetails AS (
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
PopularPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        pd.TagName 
    FROM 
        Posts p
    JOIN 
        (SELECT 
            p.Id,
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName 
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
         INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) pd 
    ON true
    WHERE 
        p.Score > 50
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    rp.Title AS PopularPostTitle,
    rp.Score AS PopularPostScore,
    rp.ViewCount AS PopularPostViews,
    COALESCE(cte.PostId, 0) AS RecentPostId,
    COALESCE(cte.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(cte.CreationDate, '1970-01-01') AS RecentPostDate
FROM 
    UserDetails ud
LEFT JOIN 
    RecursiveCTE cte ON ud.UserId = cte.OwnerUserId AND cte.rn = 1
LEFT JOIN 
    PopularPosts rp ON rp.Title LIKE CONCAT('%', ud.DisplayName, '%')
WHERE 
    ud.Reputation > 1000
ORDER BY 
    ud.Reputation DESC, 
    rp.Score DESC
LIMIT 10;
