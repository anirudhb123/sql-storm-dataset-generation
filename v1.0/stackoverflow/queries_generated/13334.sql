-- Performance Benchmarking Query Example

-- 1. Count the number of Posts, Comments, and Users
WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts
),
CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM Comments
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(CASE WHEN Reputation > 0 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM Users
)

SELECT 
    p.TotalPosts,
    p.TotalQuestions,
    p.TotalAnswers,
    c.TotalComments,
    u.TotalUsers,
    u.ActiveUsers
FROM PostCounts p, CommentCounts c, UserCounts u;

-- 2. Average score of Posts and Comments
SELECT 
    AVG(p.Score) AS AveragePostScore,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId;

-- 3. Top 10 users by reputation
SELECT 
    Id, 
    DisplayName, 
    Reputation
FROM 
    Users
ORDER BY 
    Reputation DESC
LIMIT 10;

-- 4. Average number of comments per post
SELECT 
    AVG(CommentCount) AS AverageCommentsPerPost
FROM 
    Posts;

-- 5. Total votes per VoteType
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
