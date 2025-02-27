
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS Count
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
AvgViews AS (
    SELECT 
        OwnerUserId,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        OwnerUserId
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(tc.Count, 0) AS TagCount,
        COALESCE(ac.AvgViewCount, 0) AS AvgViewCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN TagCounts tc ON u.Id = (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL ORDER BY RAND() LIMIT 1)
    LEFT JOIN AvgViews ac ON u.Id = ac.OwnerUserId
    LEFT JOIN BadgeCounts bc ON u.Id = bc.UserId
),
RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        TagCount,
        AvgViewCount,
        BadgeCount,
        RANK() OVER (ORDER BY TagCount DESC, AvgViewCount DESC, BadgeCount DESC) AS UserRank
    FROM 
        TopUsers
)
SELECT 
    DisplayName,
    TagCount,
    AvgViewCount,
    BadgeCount,
    UserRank
FROM 
    RankedUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
