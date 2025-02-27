-- Performance Benchmarking SQL Query

-- 1. Count the number of posts by type.
SELECT pt.Name as PostType, COUNT(p.Id) as PostCount
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name;

-- 2. Retrieve the average score of questions with accepted answers.
SELECT AVG(p.Score) as AverageScore
FROM Posts p
WHERE p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL;

-- 3. Get the number of users with at least one badge.
SELECT COUNT(DISTINCT u.Id) as UserCountWithBadges
FROM Users u
JOIN Badges b ON u.Id = b.UserId;

-- 4. Analyze the distribution of votes for posts.
SELECT vt.Name as VoteType, COUNT(v.Id) as VoteCount
FROM Votes v
JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY vt.Name;

-- 5. Average view count of posts across all post types.
SELECT pt.Name as PostType, AVG(p.ViewCount) as AverageViewCount
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name;

-- 6. Number of comments per post type.
SELECT pt.Name as PostType, COUNT(c.Id) as CommentCount
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY pt.Name;

-- 7. Total number of posts created by users from different locations.
SELECT u.Location, COUNT(p.Id) as PostCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
GROUP BY u.Location;

-- 8. Count of badges by class type.
SELECT b.Class as BadgeClass, COUNT(b.Id) as BadgeCount
FROM Badges b
GROUP BY b.Class;

-- 9. Get the last activity date of posts and corresponding title.
SELECT p.Title, p.LastActivityDate
FROM Posts p
ORDER BY p.LastActivityDate DESC
LIMIT 10;

-- 10. Number of posts created in each year.
SELECT EXTRACT(YEAR FROM p.CreationDate) as Year, COUNT(p.Id) as PostCount
FROM Posts p
GROUP BY Year
ORDER BY Year;
