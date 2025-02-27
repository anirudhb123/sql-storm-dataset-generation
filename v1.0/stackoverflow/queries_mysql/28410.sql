
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 11, 12, 13) THEN 1 ELSE 0 END) AS CloseActionCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
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
        CloseActionCount,
        AvgUserReputation,
        @row_number := @row_number + 1 AS Rank
    FROM 
        TagStats, (SELECT @row_number := 0) AS r
    ORDER BY 
        PostCount DESC
)
SELECT 
    Rank,
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    CloseActionCount,
    AvgUserReputation
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
