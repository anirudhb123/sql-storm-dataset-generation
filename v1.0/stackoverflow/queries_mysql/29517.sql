
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
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
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
        @row_number := IF(@prev_post_count = PostCount, @row_number, @row_number + 1) AS Rank,
        @prev_post_count := PostCount 
    FROM 
        TagStats, (SELECT @row_number := 0, @prev_post_count := NULL) AS init
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
)
SELECT 
    T.TagName, 
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.TotalScore,
    CONCAT(
        'Tag: ', T.TagName,
        ' | Posts: ', T.PostCount,
        ' | Questions: ', T.QuestionCount,
        ' | Answers: ', T.AnswerCount,
        ' | Views: ', T.TotalViews,
        ' | Score: ', T.TotalScore
    ) AS TagSummary
FROM 
    TopTags T
WHERE 
    Rank <= 10
ORDER BY 
    T.Rank;
