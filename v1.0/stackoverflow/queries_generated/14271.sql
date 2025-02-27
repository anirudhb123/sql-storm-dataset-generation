-- Performance benchmarking query for Stackoverflow schema

-- This query retrieves the number of posts, average score of questions, 
-- average view count, and maximum score of posts created by each user,
-- along with the total number of votes they received on their posts.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
    AVG(p.ViewCount) AS AvgViewCount,
    MAX(p.Score) AS MaxPostScore,
    SUM(v.Id IS NOT NULL) AS TotalVotesReceived
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
