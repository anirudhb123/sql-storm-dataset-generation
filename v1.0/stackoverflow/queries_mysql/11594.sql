
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
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
        QuestionsCount,
        AnswersCount,
        TotalScore,
        AverageViews,
        @rank := @rank + 1 AS Rank
    FROM 
        UserPosts, (SELECT @rank := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    Rank,
    UserId,
    DisplayName,
    PostCount,
    QuestionsCount,
    AnswersCount,
    TotalScore,
    AverageViews
FROM 
    TopUsers
WHERE 
    Rank <= 10;
