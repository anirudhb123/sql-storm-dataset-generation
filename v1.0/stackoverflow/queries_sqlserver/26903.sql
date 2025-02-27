
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
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(value)
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    TopTags T ON R.Tags LIKE '%' + T.Tag + '%'
WHERE 
    R.RankByViews <= 5
ORDER BY 
    R.Tags, R.RankByViews;
