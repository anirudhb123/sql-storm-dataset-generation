-- Performance Benchmarking SQL Query

-- 1. Count total number of users
SELECT COUNT(*) AS TotalUsers
FROM Users;

-- 2. Count total number of posts by type
SELECT PostTypeId, COUNT(*) AS TotalPosts
FROM Posts
GROUP BY PostTypeId;

-- 3. Average reputation of users
SELECT AVG(Reputation) AS AverageReputation
FROM Users;

-- 4. Count of badges received by users
SELECT UserId, COUNT(*) AS TotalBadges
FROM Badges
GROUP BY UserId;

-- 5. Total votes received per post
SELECT PostId, COUNT(*) AS TotalVotes
FROM Votes
GROUP BY PostId;

-- 6. Average score of posts
SELECT AVG(Score) AS AveragePostScore
FROM Posts;

-- 7. Count of comments per post
SELECT PostId, COUNT(*) AS TotalComments
FROM Comments
GROUP BY PostId;

-- 8. Find most common close reasons
SELECT Comment AS CloseReason, COUNT(*) AS ReasonCount
FROM PostHistory
WHERE PostHistoryTypeId IN (10, 11) -- Closed and Reopened
GROUP BY Comment
ORDER BY ReasonCount DESC
LIMIT 5;

-- 9. Total number of tags used
SELECT COUNT(*) AS TotalTags
FROM Tags;

-- 10. Total count of views by post
SELECT PostId, SUM(ViewCount) AS TotalViews
FROM Posts
GROUP BY PostId;
