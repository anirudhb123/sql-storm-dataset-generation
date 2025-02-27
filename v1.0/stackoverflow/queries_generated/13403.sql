-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.TotalViews,
    ups.AverageScore,
    RANK() OVER (ORDER BY ups.TotalPosts DESC) AS PostRank
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
ORDER BY 
    ups.TotalPosts DESC, ups.AverageScore DESC
LIMIT 10;
