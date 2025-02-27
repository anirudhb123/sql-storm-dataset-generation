
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiPostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        WikiPostCount, 
        TotalViews, 
        TotalScore,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) r
    WHERE 
        PostCount > 0
    ORDER BY 
        TotalScore DESC
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.WikiPostCount,
    tu.TotalViews,
    tu.TotalScore,
    (SELECT GROUP_CONCAT(t.TagName SEPARATOR ', ') 
     FROM Posts p 
     JOIN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS tag
           FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
           WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag
     JOIN Tags t ON t.TagName = tag 
     WHERE p.OwnerUserId = tu.UserId) AS AssociatedTags
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
