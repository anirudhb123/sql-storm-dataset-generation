
WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
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
        Posts p ON p.Tags LIKE CONCAT('%', ts.TagName, '%')
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
