
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName ASC SEPARATOR ', ') AS TopUsers
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
        AverageScore,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        Users u, (SELECT @userRank := 0) r
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    ROUND(tt.AverageScore, 2) AS AverageScore,
    tt.Rank,
    tu.DisplayName AS TopUser
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tu.UserRank <= 5
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.Rank, tu.Reputation DESC;
