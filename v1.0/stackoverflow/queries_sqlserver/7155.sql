
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiPostCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore
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
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.WikiPostCount,
    tu.TotalViews,
    tu.TotalScore,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Posts p 
     CROSS APPLY STRING_SPLIT(p.Tags, ',') AS tag
     JOIN Tags t ON t.TagName = tag.value 
     WHERE p.OwnerUserId = tu.UserId) AS AssociatedTags
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
