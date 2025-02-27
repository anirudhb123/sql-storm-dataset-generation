
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS Questions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS Answers,
        COALESCE(SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', numbers.n), '<>', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Questions,
    ups.Answers,
    ups.TotalScore,
    ups.TotalPosts,
    uwb.BadgeCount,
    uwb.BadgeNames,
    pt.TagName
FROM 
    UserPostStats ups
LEFT JOIN 
    UserWithBadges uwb ON ups.UserId = uwb.UserId
CROSS JOIN 
    PopularTags pt
WHERE 
    ups.TotalPosts > 5
AND 
    (uwb.BadgeCount IS NULL OR uwb.BadgeCount > 2)
ORDER BY 
    ups.TotalScore DESC,
    pt.TagCount DESC
LIMIT 50;
