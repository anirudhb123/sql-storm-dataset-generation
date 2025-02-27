
WITH UserTagCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM Posts P 
         INNER JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                      UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) T
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName, T.TagName
),
RankedTags AS (
    SELECT 
        UserId,
        DisplayName,
        TagName,
        TagCount,
        RANK() OVER (PARTITION BY UserId ORDER BY TagCount DESC) AS TagRank
    FROM 
        UserTagCounts
),
TopUserTags AS (
    SELECT 
        UserId,
        DisplayName,
        TagName
    FROM 
        RankedTags
    WHERE 
        TagRank = 1
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Name AS BadgeName,
        B.Class,
        B.Date
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Class = 1 
)
SELECT 
    TUT.DisplayName AS TopUser,
    TUT.TagName AS FavoriteTag,
    COUNT(UB.BadgeName) AS GoldBadges,
    SUM(CASE WHEN Post.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS RecentPosts
FROM 
    TopUserTags TUT
LEFT JOIN 
    Posts Post ON TUT.UserId = Post.OwnerUserId
LEFT JOIN 
    UserBadges UB ON TUT.UserId = UB.UserId
GROUP BY 
    TUT.DisplayName, TUT.TagName
ORDER BY 
    GoldBadges DESC, RecentPosts DESC
LIMIT 10;
