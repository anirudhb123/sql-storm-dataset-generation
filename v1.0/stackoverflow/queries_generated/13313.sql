-- Performance benchmarking SQL query

-- Query 1: Count the total number of users
SELECT COUNT(*) AS TotalUsers FROM Users;

-- Query 2: Get the average reputation of users
SELECT AVG(Reputation) AS AverageReputation FROM Users;

-- Query 3: Count the number of posts by type
SELECT PostTypeId, COUNT(*) AS PostCount
FROM Posts
GROUP BY PostTypeId;

-- Query 4: Get the top 5 tags by post count
SELECT TagName, COUNT(*) AS PostCount
FROM Tags
JOIN Posts ON Tags.Id = Posts.Tags
GROUP BY TagName
ORDER BY PostCount DESC
LIMIT 5;

-- Query 5: Get the most active users based on reputation and post count
SELECT U.Id, U.DisplayName, U.Reputation, COUNT(P.Id) AS PostCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
GROUP BY U.Id, U.DisplayName, U.Reputation
ORDER BY COUNT(P.Id) DESC, U.Reputation DESC
LIMIT 10;

-- Query 6: Total votes and their type summary
SELECT VoteTypeId, COUNT(*) AS VoteCount
FROM Votes
GROUP BY VoteTypeId;

-- Query 7: Find the average score of posts by type
SELECT PostTypeId, AVG(Score) AS AverageScore
FROM Posts
GROUP BY PostTypeId;

-- Query 8: Summary of post edits history
SELECT P.Id AS PostId, COUNT(H.Id) AS EditCount
FROM Posts P
JOIN PostHistory H ON P.Id = H.PostId
WHERE H.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
GROUP BY P.Id
ORDER BY EditCount DESC
LIMIT 10;
