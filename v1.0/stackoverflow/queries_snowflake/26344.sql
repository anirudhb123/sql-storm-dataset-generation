
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        LISTAGG(DISTINCT u.DisplayName, ', ') WITHIN GROUP (ORDER BY u.DisplayName) AS TopUsers
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || '<' || t.TagName || '>'
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01'::date) 
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageReputation,
        TopUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagStatistics
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AverageReputation,
    TopUsers
FROM TopTags
WHERE Rank <= 10;
