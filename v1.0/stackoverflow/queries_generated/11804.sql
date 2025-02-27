WITH UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        SUM(v.VoteTypeId = 1) AS TotalAccepted,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
BenchmarkResults AS (
    SELECT
        *,
        (TotalUpvotes - TotalDownvotes) AS NetVotes,
        (TotalQuestions + TotalAnswers) AS TotalContributions,
        (AverageScore / NULLIF(TotalContributions, 0)) AS ScorePerContribution
    FROM 
        UserPerformance
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpvotes,
    TotalDownvotes,
    NetVotes,
    TotalAccepted,
    AverageScore,
    TotalContributions,
    ScorePerContribution
FROM 
    BenchmarkResults
ORDER BY 
    TotalContributions DESC;
