-- Performance Benchmarking Query

-- Measure the number of users, posts, comments, and votes along with average reputation

SELECT 
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    AVG(Reputation) AS AverageReputation
FROM Users;

-- Measure average post view count and average score by PostType

SELECT 
    pt.Name AS PostTypeName,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name;

-- Measure average number of answers and comments per post type

SELECT 
    pt.Name AS PostTypeName,
    AVG(p.AnswerCount) AS AverageAnswers,
    AVG(p.CommentCount) AS AverageComments
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name;

-- Measure the frequency of post history types

SELECT 
    pht.Name AS PostHistoryTypeName,
    COUNT(ph.Id) AS Frequency
FROM PostHistory ph
JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY pht.Name
ORDER BY Frequency DESC;

-- Measure user activity by creation date

SELECT 
    DATE(CreationDate) AS ActivityDate,
    COUNT(*) AS UserCount
FROM Users
GROUP BY ActivityDate
ORDER BY ActivityDate;
