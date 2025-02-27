-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageScore,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS rnk
    FROM 
        UserPostStats
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AverageScore,
    TotalViews
FROM 
    TopActiveUsers
WHERE 
    rnk <= 10;  -- Top 10 Users by Post Count

-- Counting the number of Posts and sort it by creation date for performance testing
SELECT 
    COUNT(*) AS TotalPosts,
    MIN(CreationDate) AS EarliestPost,
    MAX(CreationDate) AS LatestPost
FROM 
    Posts;

-- Aggregating Votes by Type for Performance Testing
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
