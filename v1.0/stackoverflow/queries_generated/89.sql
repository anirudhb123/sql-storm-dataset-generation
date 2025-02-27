WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgReputation,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AvgReputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.UserId = rp.Author
WHERE 
    tu.PostRank <= 10
    AND (rp.RecentPostRank IS NULL OR rp.Score > 10)  -- Only include high-scoring recent posts or none
ORDER BY 
    tu.PostRank, rp.Score DESC NULLS LAST;
