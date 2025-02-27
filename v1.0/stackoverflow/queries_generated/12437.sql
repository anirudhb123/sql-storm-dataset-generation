-- Performance Benchmarking Query: Fetching the count of posts, average score of questions,
-- and total number of users along with the highest reputation user.

SELECT
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) AS AvgQuestionScore,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT MAX(Reputation) FROM Users) AS HighestReputation
FROM
    DUAL; -- Adjusting for SQL dialects that may not support multiple select statements
