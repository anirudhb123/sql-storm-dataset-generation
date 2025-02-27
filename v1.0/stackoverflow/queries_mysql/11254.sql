
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
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
        TotalScore, 
        AvgViewCount,
        (@rank := @rank + 1) AS Rank
    FROM 
        UserPostStats, (SELECT @rank := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    TotalScore, 
    AvgViewCount
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
