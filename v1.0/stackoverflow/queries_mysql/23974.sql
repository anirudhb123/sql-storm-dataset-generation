
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(ub.BadgeNames, 'No Gold Badges') AS GoldBadges,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.CreationDate AS TopPostDate,
    ts.TagName AS RelatedTag,
    ts.TotalPosts AS TotalPostsWithTag,
    ts.PopularPosts AS PopularPostsWithTag
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    TagStatistics ts ON ts.TagName IN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1) 
        FROM 
            (SELECT @num := @num + 1 AS n 
             FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                   UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 
                   UNION SELECT 10) numbers, (SELECT @num := 0) num) numbers
        WHERE 
            numbers.n <= (LENGTH(rp.Tags) - LENGTH(REPLACE(rp.Tags, '><', '')) + 1)
    )
WHERE 
    u.Reputation >= 1000 
ORDER BY 
    u.Reputation DESC, 
    TopPostScore DESC
LIMIT 10 OFFSET 0;
