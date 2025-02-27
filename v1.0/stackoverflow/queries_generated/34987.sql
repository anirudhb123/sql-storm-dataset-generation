WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        CAST(0 AS INT) AS Level,
        CONCAT(DisplayName, ' (Level: 0)') AS DisplayInfo
    FROM Users
    WHERE Reputation > 0

    UNION ALL 

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1 AS Level,
        CONCAT(u.DisplayName, ' (Level: ', ur.Level + 1, ')') AS DisplayInfo
    FROM Users u
    JOIN UserReputation ur ON u.Reputation <= ur.Reputation / 2
    WHERE u.Reputation > 0 AND ur.Level < 5
), 
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        CreationDate,
        DisplayInfo,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pm.PostCount, 0) AS PostCount,
        COALESCE(pm.QuestionCount, 0) AS QuestionCount,
        COALESCE(pm.AnswerCount, 0) AS AnswerCount,
        COALESCE(pm.AverageScore, 0) AS AverageScore,
        COALESCE(pm.TotalViews, 0) AS TotalViews,
        (u.Reputation + COALESCE(pm.TotalViews, 0) * 0.1 + COALESCE(pm.AverageScore, 0) * 10) AS TotalScore
    FROM Users u
    LEFT JOIN PostMetrics pm ON u.Id = pm.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.AverageScore,
    us.TotalViews,
    us.TotalScore,
    tru.DisplayInfo
FROM 
    UserScores us
JOIN 
    TopUsers tru ON us.UserId = tru.UserId
WHERE 
    tru.Rank <= 10
ORDER BY 
    TotalScore DESC, 
    us.DisplayName;
