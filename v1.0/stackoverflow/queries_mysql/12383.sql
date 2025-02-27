
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViews
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
        TotalViews,
        AvgScore,
        AvgViews,
        @row_number := IF(@prev_score = TotalScore, @row_number, @row_number + 1) AS UserRank,
        @prev_score := TotalScore
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_score := NULL) AS init
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
    TotalViews, 
    AvgScore, 
    AvgViews
FROM 
    TopUsers
WHERE 
    UserRank <= 10;
