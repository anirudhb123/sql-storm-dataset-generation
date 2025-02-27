
WITH TagOccurrences AS (
    SELECT 
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + 1 as n FROM (SELECT 0 as N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a 
        CROSS JOIN (SELECT 0 as N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagOccurrences, (SELECT @rank := 0) r
    WHERE 
        TagCount > 1 
    ORDER BY 
        TagCount DESC
),
ActivitySummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(TIMESTAMPDIFF(SECOND, P.CreationDate, '2024-10-01 12:34:56')) AS AveragePostAgeInSeconds,
        AVG(TIMESTAMPDIFF(SECOND, C.CreationDate, '2024-10-01 12:34:56')) AS AverageCommentAgeInSeconds
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    US.TotalScore,
    US.QuestionCount,
    US.AnswerCount,
    COALESCE(TT.TagName, 'No Tags') AS PopularTag,
    COALESCE(TT.TagCount, 0) AS TagCount,
    ASUM.TotalPosts,
    ASUM.TotalComments,
    ASUM.AveragePostAgeInSeconds,
    ASUM.AverageCommentAgeInSeconds
FROM 
    Users U
JOIN 
    UserScores US ON U.Id = US.UserId
LEFT JOIN 
    TopTags TT ON TT.Rank = 1  
JOIN 
    ActivitySummary ASUM ON ASUM.OwnerUserId = U.Id
ORDER BY 
    US.TotalScore DESC, 
    US.QuestionCount DESC;
