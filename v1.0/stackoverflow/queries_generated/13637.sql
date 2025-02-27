-- Performance benchmarking SQL query for the Stack Overflow schema

-- 1. Benchmarking the average reputation of users who have posted questions
SELECT AVG(u.Reputation) AS AverageReputation
FROM Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1;  -- PostTypeId = 1 corresponds to Questions

-- 2. Count of closed questions by close reason
SELECT 
    cr.Name AS CloseReason,
    COUNT(ph.Id) AS CloseCount
FROM PostHistory ph
INNER JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
WHERE ph.PostHistoryTypeId = 10  -- PostHistoryTypeId = 10 corresponds to Post Closed
GROUP BY cr.Name
ORDER BY CloseCount DESC;

-- 3. Top 10 users by total score of their posts
SELECT 
    u.DisplayName,
    SUM(p.Score) AS TotalScore
FROM Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName
ORDER BY TotalScore DESC
LIMIT 10;

-- 4. Average number of answers per question
SELECT 
    AVG(answer_counts.AnswerCount) AS AverageAnswersPerQuestion
FROM (
    SELECT 
        p.Id,
        COUNT(a.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1  -- PostTypeId = 1 corresponds to Questions
    GROUP BY p.Id
) answer_counts;

-- 5. Number of comments per post type
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount
FROM Comments c
INNER JOIN Posts p ON c.PostId = p.Id
INNER JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name
ORDER BY CommentCount DESC;

-- 6. User activity: Number of posts and votes for the top 5 users
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    COUNT(v.Id) AS VoteCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY u.DisplayName
ORDER BY PostCount DESC, VoteCount DESC
LIMIT 5;
