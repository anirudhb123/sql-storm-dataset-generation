WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS RankByTag
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
        AND P.CreationDate > NOW() - INTERVAL '1 year' 
        AND P.ViewCount > 100
),
TagDetails AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT RP.PostId) AS QuestionCount,
        SUM(RP.AnswerCount) AS TotalAnswers,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.ViewCount) AS TotalViews
    FROM 
        RankedPosts RP
    JOIN 
        UNNEST(string_to_array(RP.Tags, '><')) AS Tag(T.TagName) ON true
    GROUP BY 
        T.TagName
)
SELECT 
    TD.TagName,
    TD.QuestionCount,
    TD.TotalAnswers,
    TD.AverageScore,
    TD.TotalViews
FROM 
    TagDetails TD
WHERE 
    TD.QuestionCount >= 5 -- Only tags with 5 or more questions
ORDER BY 
    TD.TotalAnswers DESC,
    TD.AverageScore DESC;

This SQL query aims to benchmark string processing by analyzing questions over the past year in a StackOverflow-like schema. It first ranks questions by creation date within each tag, filtering those with significant views. The subsequent step aggregates tag statistics and calculates total views, average post scores, and total answers for tags with at least five questions, allowing for insights into the most engaging topics. The results are ordered for quick identification of popular tags.
