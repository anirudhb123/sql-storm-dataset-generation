-- Performance Benchmarking SQL Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        COUNT(DISTINCT q.Id) AS TotalQuestions,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,  -- UpMod
        SUM(v.VoteTypeId = 3) AS TotalDownVotes  -- DownMod
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts q ON u.Id = q.OwnerUserId AND q.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    PostRank,
    UpVoteRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10 OR UpVoteRank <= 10
ORDER BY 
    PostRank, UpVoteRank;
