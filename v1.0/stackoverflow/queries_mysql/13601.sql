
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END) AS TotalScore,
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
        @row_number := IF(@prev_total_score = TotalScore, @row_number, @row_number + 1) AS Rank,
        @prev_total_score := TotalScore
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_total_score := NULL) AS vars
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
    AvgViewCount,
    Rank
FROM 
    TopUsers
WHERE 
    Rank <= 10;
