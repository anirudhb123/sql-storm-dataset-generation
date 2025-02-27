
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgScore,
        TotalViews,
        @row_number := @row_number + 1 AS Ranking
    FROM 
        UserReputation, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    AvgScore, 
    TotalViews 
FROM 
    TopUsers 
WHERE 
    Ranking <= 10
ORDER BY 
    Ranking;
