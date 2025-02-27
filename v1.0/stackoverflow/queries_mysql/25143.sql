
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT a.N + b.N * 10 + 1 n FROM 
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount
    FROM 
        TagCounts
    WHERE 
        PostCount > (
            SELECT 
                AVG(PostCount) FROM TagCounts
        )
),
UserBadgeCounts AS (
    SELECT
        B.UserId,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    U.TotalScore,
    U.TotalPosts,
    COALESCE(UB.TotalBadges, 0) AS TotalBadges,
    GROUP_CONCAT(PT.Tag ORDER BY PT.Tag SEPARATOR ', ') AS PopularTagsAssociated
FROM 
    UserReputation U
LEFT JOIN 
    UserBadgeCounts UB ON U.UserId = UB.UserId
LEFT JOIN 
    PopularTags PT ON EXISTS (
        SELECT 1 
        FROM Posts P
        WHERE P.Tags LIKE CONCAT('%', PT.Tag, '%')
        AND P.OwnerUserId = U.UserId
    )
WHERE 
    U.TotalPosts > 5
GROUP BY 
    U.DisplayName, U.TotalScore, U.TotalPosts, UB.TotalBadges
ORDER BY 
    U.TotalScore DESC
