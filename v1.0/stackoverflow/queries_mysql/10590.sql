
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        TotalViews, 
        AverageScore,
        @rank := @rank + 1 AS Rank
    FROM UserPostCounts, (SELECT @rank := 0) r
    ORDER BY PostCount DESC
)

SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    TotalViews, 
    AverageScore
FROM TopUsers
WHERE Rank <= 10;
