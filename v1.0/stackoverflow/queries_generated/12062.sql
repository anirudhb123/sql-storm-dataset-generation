-- Performance benchmarking query to analyze the distribution and activity of posts, users, and votes in the Stack Overflow schema.

-- Select the total number of posts, answers, and their average score.
SELECT 
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p;

-- Select the number of users and average reputation.
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- Select the total number of votes and distinguish between vote types.
SELECT 
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS TotalAcceptedVotes
FROM 
    Votes v;

-- Combine the above results for a comprehensive performance overview.
WITH PostStats AS (
    SELECT 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
),
UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
),
VoteStats AS (
    SELECT 
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS TotalAcceptedVotes
    FROM 
        Votes v
)
SELECT 
    p.TotalPosts,
    p.TotalQuestions,
    p.TotalAnswers,
    p.AverageScore,
    p.AverageViewCount,
    u.TotalUsers,
    u.AverageReputation,
    v.TotalVotes,
    v.TotalUpVotes,
    v.TotalDownVotes,
    v.TotalAcceptedVotes
FROM 
    PostStats p, UserStats u, VoteStats v;
