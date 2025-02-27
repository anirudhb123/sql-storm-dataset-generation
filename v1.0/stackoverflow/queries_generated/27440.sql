WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViewCount,
        TotalScore,
        TopContributors,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        TagStatistics
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViewCount,
    TotalScore,
    TopContributors
FROM 
    TopTags
WHERE 
    ScoreRank <= 10
ORDER BY 
    TotalScore DESC;
