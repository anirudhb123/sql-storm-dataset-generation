-- Performance Benchmarking SQL Query

-- 1. Measure the time taken to count the total number of posts in the Posts table
EXPLAIN ANALYZE
SELECT COUNT(*) AS TotalPosts
FROM Posts;

-- 2. Fetch details of posts along with the total number of comments for each post
EXPLAIN ANALYZE
SELECT p.Id AS PostId, p.Title, COUNT(c.Id) AS CommentCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Id, p.Title;

-- 3. Calculate average score of posts by post type
EXPLAIN ANALYZE
SELECT pt.Name AS PostType, AVG(p.Score) AS AverageScore
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name;

-- 4. Identify the top 10 users by reputation with their total number of posts
EXPLAIN ANALYZE
SELECT u.Id AS UserId, u.DisplayName, u.Reputation, COUNT(p.Id) AS TotalPosts
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Id, u.DisplayName, u.Reputation
ORDER BY u.Reputation DESC
LIMIT 10;

-- 5. Analyze the distribution of votes across post types
EXPLAIN ANALYZE
SELECT pt.Name AS PostType, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
       SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY pt.Name;

-- 6. Find posts that have been closed and their respective close reasons
EXPLAIN ANALYZE
SELECT p.Id AS PostId, p.Title, ph.CreationDate, ph.Comment
FROM PostHistory ph
JOIN Posts p ON ph.PostId = p.Id
WHERE ph.PostHistoryTypeId IN (10, 11) -- 10 = Post Closed, 11 = Post Reopened
ORDER BY ph.CreationDate DESC;

-- 7. Get the total number of badges per user
EXPLAIN ANALYZE
SELECT u.Id AS UserId, u.DisplayName, COUNT(b.Id) AS TotalBadges
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
GROUP BY u.Id, u.DisplayName
ORDER BY TotalBadges DESC;

-- 8. Evaluate the efficacy of tags in terms of usage
EXPLAIN ANALYZE
SELECT t.TagName, COUNT(p.Id) AS PostCount
FROM Tags t
LEFT JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
GROUP BY t.TagName
ORDER BY PostCount DESC;
