-- Performance benchmarking query for Stack Overflow schema

-- 1. Retrieve the number of posts by type (Question, Answer, etc.)
SELECT pt.Name AS PostType, 
       COUNT(p.Id) AS PostCount
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name
ORDER BY PostCount DESC;

-- 2. Benchmark user engagement by counting comments per user
SELECT u.DisplayName, 
       COUNT(c.Id) AS CommentCount
FROM Users u
LEFT JOIN Comments c ON u.Id = c.UserId
GROUP BY u.DisplayName
ORDER BY CommentCount DESC
LIMIT 10; -- Top 10 users with the most comments

-- 3. Analyze vote distribution across post types
SELECT pt.Name AS PostType, 
       vt.Name AS VoteType, 
       COUNT(v.Id) AS VoteCount
FROM Votes v
JOIN Posts p ON v.PostId = p.Id
JOIN PostTypes pt ON p.PostTypeId = pt.Id
JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY pt.Name, vt.Name
ORDER BY pt.Name, VoteCount DESC;

-- 4. Measure the average view count of posts by creation date
SELECT DATE(CreationDate) AS PostDate, 
       AVG(ViewCount) AS AverageViewCount
FROM Posts
GROUP BY PostDate
ORDER BY PostDate;

-- 5. Identify the top users by reputation among those who have made posts
SELECT u.DisplayName, 
       u.Reputation, 
       COUNT(p.Id) AS PostCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName, u.Reputation
ORDER BY u.Reputation DESC
LIMIT 10; -- Top 10 users by reputation with posts
