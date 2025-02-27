-- Performance benchmarking of various operations on the StackOverflow schema

-- 1. Retrieve count of Posts grouped by PostType and order by count descending
SELECT PostTypeId, COUNT(*) AS PostCount
FROM Posts
GROUP BY PostTypeId
ORDER BY PostCount DESC;

-- 2. Average Reputation of Users
SELECT AVG(Reputation) AS AverageReputation
FROM Users;

-- 3. Total Votes for each Post along with the Post's Title
SELECT P.Title, COUNT(V.Id) AS TotalVotes
FROM Posts P
LEFT JOIN Votes V ON P.Id = V.PostId
GROUP BY P.Id, P.Title
ORDER BY TotalVotes DESC;

-- 4. Count of Comments by PostId
SELECT PostId, COUNT(*) AS CommentCount
FROM Comments
GROUP BY PostId;

-- 5. Find Posts with highest view count
SELECT Id, Title, ViewCount
FROM Posts
ORDER BY ViewCount DESC
LIMIT 10;

-- 6. Number of Badges per User
SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount
FROM Users U
LEFT JOIN Badges B ON U.Id = B.UserId
GROUP BY U.Id;

-- 7. Fetch the latest Post Edit History
SELECT PH.PostId, PH.CreationDate, PH.UserDisplayName, PH.Comment
FROM PostHistory PH
WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
ORDER BY PH.CreationDate DESC
LIMIT 10;

-- 8. Users with posts that have been closed
SELECT DISTINCT U.Id, U.DisplayName
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
WHERE P.ClosedDate IS NOT NULL;

-- 9. Total number of Posts and average Score of Posts
SELECT COUNT(*) AS TotalPosts, AVG(Score) AS AverageScore
FROM Posts;

-- 10. Finding the most common close reasons
SELECT PH.Comment, COUNT(*) AS CloseReasonCount
FROM PostHistory PH
WHERE PH.PostHistoryTypeId = 10 -- Post Closed
GROUP BY PH.Comment
ORDER BY CloseReasonCount DESC;
