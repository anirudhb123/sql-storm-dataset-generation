
;WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount
FROM 
    UserPostStats
WHERE 
    PostCount > 0
ORDER BY 
    Reputation DESC, PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
