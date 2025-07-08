
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
        TRIM(REGEXP_SUBSTR(Tags, '[^<>]+', 1, seq)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 100)) AS seq
    WHERE 
        Tags IS NOT NULL
        AND SEQ <= REGEXP_COUNT(Tags, '<>') + 1
    GROUP BY 
        TRIM(REGEXP_SUBSTR(Tags, '[^<>]+', 1, seq))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames
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
