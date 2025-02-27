WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostRanking AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        u.TotalPosts,
        u.TotalQuestions,
        u.TotalAnswers,
        u.TotalUpvotes,
        u.TotalDownvotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics u
)
SELECT 
    pr.DisplayName,
    pr.Reputation,
    pr.TotalPosts,
    pr.TotalQuestions,
    pr.TotalAnswers,
    pr.TotalUpvotes,
    pr.TotalDownvotes,
    pr.ReputationRank
FROM 
    PostRanking pr
WHERE 
    pr.TotalPosts > 5 AND pr.TotalAnswers > 10
ORDER BY 
    pr.Reputation DESC, pr.TotalUpvotes DESC
LIMIT 50;
