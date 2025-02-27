
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        AVG(ISNULL(p.Score, 0)) AS AverageScore
    FROM
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.AverageScore,
    u.Reputation
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
ORDER BY 
    u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
