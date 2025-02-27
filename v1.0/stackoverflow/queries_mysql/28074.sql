
WITH TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        TS.Tag,
        TS.PostCount,
        US.DisplayName,
        US.TotalPosts,
        @Rank := @Rank + 1 AS TagRank
    FROM 
        TagStats TS
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', TS.Tag, '%')
    JOIN 
        UserStats US ON P.OwnerUserId = US.UserId
    CROSS JOIN 
        (SELECT @Rank := 0) r
    WHERE 
        TS.PostCount > 10
)
SELECT 
    PT.Tag,
    PT.PostCount,
    PT.DisplayName,
    PT.TotalPosts,
    US.TotalScore,
    PT.TagRank
FROM 
    PopularTags PT
JOIN 
    UserStats US ON PT.DisplayName = US.DisplayName
WHERE 
    PT.TagRank <= 5
ORDER BY 
    PT.TagRank;
