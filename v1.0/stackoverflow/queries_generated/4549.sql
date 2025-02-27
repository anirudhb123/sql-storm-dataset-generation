WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, TotalQuestions, TotalAnswers, AvgPostScore
    FROM 
        UserPostStats
    WHERE 
        PostRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AvgPostScore,
    (SELECT COUNT(DISTINCT c.Id) 
     FROM Comments c 
     WHERE c.UserId = tu.UserId) AS TotalComments,
    (SELECT 
        STRING_AGG(DISTINCT pt.Name, ', ') 
     FROM 
        PostHistory ph 
     JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
     WHERE 
        ph.UserId = tu.UserId) AS PostHistoryTypes
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId 
WHERE 
    b.Class = 1 -- Gold badges
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalQuestions, tu.TotalAnswers, tu.AvgPostScore
ORDER BY 
    tu.TotalPosts DESC, tu.AvgPostScore DESC;
