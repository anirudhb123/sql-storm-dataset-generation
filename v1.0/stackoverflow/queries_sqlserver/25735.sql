
WITH TagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS Count
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
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
    LEFT JOIN TagCounts tc ON u.Id = (SELECT TOP 1 OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL ORDER BY NEWID())
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
