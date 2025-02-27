
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        TotalViews, 
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 0
)
SELECT 
    T.TagName, 
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.TotalScore,
    'Tag: ' + T.TagName +
    ' | Posts: ' + CAST(T.PostCount AS VARCHAR) +
    ' | Questions: ' + CAST(T.QuestionCount AS VARCHAR) +
    ' | Answers: ' + CAST(T.AnswerCount AS VARCHAR) +
    ' | Views: ' + CAST(T.TotalViews AS VARCHAR) +
    ' | Score: ' + CAST(T.TotalScore AS VARCHAR) AS TagSummary
FROM 
    TopTags T
WHERE 
    Rank <= 10
ORDER BY 
    T.Rank;
