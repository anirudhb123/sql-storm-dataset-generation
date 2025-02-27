-- Performance benchmarking for various operations in the StackOverflow schema

-- 1. Count total number of posts
SELECT COUNT(*) AS TotalPosts
FROM Posts;

-- 2. Get average score of accepted answers
SELECT AVG(Score) AS AverageAcceptedAnswerScore
FROM Posts
WHERE PostTypeId = 2;

-- 3. Total number of users
SELECT COUNT(*) AS TotalUsers
FROM Users;

-- 4. Find the most active users (by number of posts)
SELECT OwnerUserId, COUNT(*) AS PostCount
FROM Posts
GROUP BY OwnerUserId
ORDER BY PostCount DESC
LIMIT 10;

-- 5. Count the number of comments on posts
SELECT P.Id AS PostId, COUNT(C.Id) AS CommentCount
FROM Posts P
LEFT JOIN Comments C ON P.Id = C.PostId
GROUP BY P.Id
ORDER BY CommentCount DESC
LIMIT 10;

-- 6. Find posts with the most views
SELECT Id, ViewCount
FROM Posts
ORDER BY ViewCount DESC
LIMIT 10;

-- 7. Executing a JOIN to get post titles with their tags
SELECT P.Title, P.Tags
FROM Posts P
WHERE P.PostTypeId = 1; -- Only questions

-- 8. Count of badges per user
SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount
FROM Users U
LEFT JOIN Badges B ON U.Id = B.UserId
GROUP BY U.Id
ORDER BY BadgeCount DESC
LIMIT 10;

-- 9. Analyze post history changes by type
SELECT PHT.PostHistoryTypeId, COUNT(*) AS ChangesCount
FROM PostHistory PHT
GROUP BY PHT.PostHistoryTypeId
ORDER BY ChangesCount DESC;

-- 10. Get the average number of answers per question
SELECT AVG(AnswerCount) AS AverageAnswersPerQuestion
FROM Posts
WHERE PostTypeId = 1; -- Only questions
