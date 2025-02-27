-- Perform performance benchmarking by measuring the execution time of various queries
-- Here are a few benchmark queries to assess performance across different tables in the StackOverflow schema

-- 1. Count of Posts grouped by PostTypeId (simple aggregation)
SELECT PostTypeId, COUNT(*) AS PostCount
FROM Posts
GROUP BY PostTypeId;

-- 2. Average Reputation of Users who have posted Questions
SELECT AVG(Reputation) AS AverageReputation
FROM Users
WHERE Id IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = 1);

-- 3. Total Votes by VoteTypeId
SELECT VoteTypeId, COUNT(*) AS VoteCount
FROM Votes
GROUP BY VoteTypeId;

-- 4. Join Users and Posts to find the number of posts per user
SELECT U.DisplayName, COUNT(P.Id) AS PostCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
GROUP BY U.DisplayName;

-- 5. Find the latest edit date per post
SELECT PostId, MAX(LastEditDate) AS LatestEditDate
FROM Posts
GROUP BY PostId;

-- 6. Posts with the most comments
SELECT P.Title, COUNT(C.Id) AS CommentCount
FROM Posts P
LEFT JOIN Comments C ON P.Id = C.PostId
GROUP BY P.Title
ORDER BY CommentCount DESC
LIMIT 10;

-- 7. List of Closed Posts with their Close Reason
SELECT P.Title, PH.Comment
FROM Posts P
JOIN PostHistory PH ON P.Id = PH.PostId
WHERE PH.PostHistoryTypeId = 10;  -- Closed posts

-- 8. Tag usage frequency
SELECT T.TagName, SUM(T.Count) AS TotalUsage
FROM Tags T
GROUP BY T.TagName
ORDER BY TotalUsage DESC;

-- 9. Most Active Users by Reputation and Post Count
SELECT U.DisplayName, U.Reputation, COUNT(P.Id) AS PostCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
GROUP BY U.DisplayName, U.Reputation
ORDER BY PostCount DESC;

-- 10. Average answer score for each post
SELECT P.Id, AVG(P.Score) AS AverageScore
FROM Posts P
WHERE P.PostTypeId = 2  -- Answers
GROUP BY P.Id;
