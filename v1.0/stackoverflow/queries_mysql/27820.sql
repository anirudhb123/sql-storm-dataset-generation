
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
        AVG(p.Score) AS AvgScore,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') AS Contributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        AcceptedAnswersCount,
        AvgScore,
        Contributors,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStats, (SELECT @rank := 0) AS r
    ORDER BY 
        PostCount DESC
)
SELECT 
    TagName,
    PostCount,
    AcceptedAnswersCount,
    AvgScore,
    Contributors
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    AvgScore DESC;
