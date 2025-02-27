
WITH TagStats AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(value)
),
Analytics AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        TagStats ts
    JOIN 
        Posts p ON p.Tags LIKE '%' + ts.TagName + '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        ts.TagName, ts.PostCount
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AcceptedAnswers,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        Analytics
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AcceptedAnswers,
    AvgReputation
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
