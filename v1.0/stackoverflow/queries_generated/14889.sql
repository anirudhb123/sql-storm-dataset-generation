-- Benchmarking the performance of query execution time for various operations

-- 1. Counting total number of posts
EXPLAIN ANALYZE
SELECT COUNT(*) FROM Posts;

-- 2. Retrieving the most recent posts with their titles and creation dates
EXPLAIN ANALYZE
SELECT Title, CreationDate FROM Posts ORDER BY CreationDate DESC LIMIT 100;

-- 3. Joining Posts with Users to find post authors and their reputations
EXPLAIN ANALYZE
SELECT p.Title, p.CreationDate, u.Reputation
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC
LIMIT 100;

-- 4. Counting votes for each post
EXPLAIN ANALYZE
SELECT p.Title, COUNT(v.Id) AS VoteCount
FROM Posts p
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY p.Title
ORDER BY VoteCount DESC
LIMIT 100;

-- 5. Finding posts with the highest answer count
EXPLAIN ANALYZE
SELECT Title, AnswerCount
FROM Posts
ORDER BY AnswerCount DESC
LIMIT 100;

-- 6. Analyzing comments per post
EXPLAIN ANALYZE
SELECT p.Title, COUNT(c.Id) AS CommentCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Title
ORDER BY CommentCount DESC
LIMIT 100;

-- 7. Retrieving badges earned by users who have posted questions
EXPLAIN ANALYZE
SELECT u.DisplayName, COUNT(b.Id) AS BadgeCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
JOIN Badges b ON u.Id = b.UserId
WHERE p.PostTypeId = 1 -- Filter for questions
GROUP BY u.DisplayName
ORDER BY BadgeCount DESC
LIMIT 100;
