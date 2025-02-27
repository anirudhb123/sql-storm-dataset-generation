
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users AS u
),
TopUsers AS (
    SELECT 
        ru.UserId,
        ru.DisplayName
    FROM 
        RankedUsers AS ru
    WHERE 
        ru.ReputationRank <= 10
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts AS p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    ISNULL(ps.PostCount, 0) AS PostCount,
    ISNULL(ps.TotalViews, 0) AS TotalViews,
    ISNULL(ps.AcceptedAnswers, 0) AS AcceptedAnswers,
    ISNULL(ps.AnswerCount, 0) AS AnswerCount,
    CASE 
        WHEN ISNULL(ps.PostCount, 0) = 0 THEN 0
        ELSE (CAST(ISNULL(ps.AcceptedAnswers, 0) AS FLOAT) / ISNULL(ps.PostCount, 0)) * 100 
    END AS AcceptanceRate
FROM 
    TopUsers AS tu
LEFT JOIN 
    PostStats AS ps ON tu.UserId = ps.OwnerUserId
ORDER BY 
    tu.DisplayName;
