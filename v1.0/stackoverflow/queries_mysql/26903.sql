
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.Tags ORDER BY P.ViewCount DESC) AS RankByViews
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, CHAR_LENGTH(Tags) - 2), '><', n.n), '>', -1)) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts
    JOIN 
        (SELECT 
            1 n UNION ALL SELECT 
            2 UNION ALL SELECT 
            3 UNION ALL SELECT 
            4 UNION ALL SELECT 
            5 UNION ALL SELECT 
            6 UNION ALL SELECT 
            7 UNION ALL SELECT 
            8 UNION ALL SELECT 
            9 UNION ALL SELECT 
            10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, CHAR_LENGTH(Tags) - 2), '><', n.n), '>', -1))
),
TopTags AS (
    SELECT 
        T.Tag,
        T.PostCount,
        T.QuestionsWithAnswers,
        T.AverageViews
    FROM 
        TagStatistics T
    ORDER BY 
        T.PostCount DESC
    LIMIT 10
)
SELECT 
    R.PostId,
    R.Title,
    R.Tags,
    R.ViewCount,
    R.AnswerCount,
    R.CreationDate,
    R.OwnerDisplayName,
    T.Tag AS MostPopularTag,
    T.PostCount AS TotalPostsForTag,
    T.QuestionsWithAnswers AS QuestionsWithAnswersForTag,
    T.AverageViews AS AvgViewsForTag,
    R.RankByViews
FROM 
    RankedPosts R
JOIN 
    TopTags T ON R.Tags LIKE CONCAT('%', T.Tag, '%')
WHERE 
    R.RankByViews <= 5
ORDER BY 
    R.Tags, R.RankByViews;
