
WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT T.TagName) AS TagCount,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM Posts P
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
               UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) T ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(T.TagName) AS Frequency
    FROM 
        Posts P
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM Posts P
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
               UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) T ON TRUE
    GROUP BY 
        T.TagName
    ORDER BY 
        Frequency DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.PostsCreated,
        U.PostsClosed,
        UT.Tags,
        PT.TagName AS MostPopularTag
    FROM 
        UserActivity U
    JOIN 
        UserTags UT ON U.UserId = UT.UserId
    LEFT JOIN 
        PopularTags PT ON TRUE
    ORDER BY 
        U.PostsCreated DESC
)
SELECT 
    DisplayName,
    PostsCreated,
    PostsClosed,
    Tags,
    MostPopularTag
FROM 
    FinalReport
WHERE 
    MostPopularTag IS NULL;
