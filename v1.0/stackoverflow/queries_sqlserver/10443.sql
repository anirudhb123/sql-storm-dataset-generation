
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        AVG(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN p.Score END) AS AvgAcceptedAnswerScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT
    UserId,
    Reputation,
    TotalPosts,
    COALESCE(AvgAcceptedAnswerScore, 0) AS AvgAcceptedAnswerScore
FROM 
    UserPostStats
ORDER BY 
    Reputation DESC, TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
