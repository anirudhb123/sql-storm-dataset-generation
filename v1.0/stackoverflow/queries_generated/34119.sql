WITH RecursivePostHierarchy AS (
    SELECT Id, PostTypeId, ParentId, Title, OwnerUserId, 
           CreationDate, LastActivityDate, Score, 
           ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS OwnershipRank
    FROM Posts
    WHERE PostTypeId IN (1, 2) -- Filtering for questions and answers
    UNION ALL
    SELECT p.Id, p.PostTypeId, p.ParentId, p.Title, p.OwnerUserId,
           p.CreationDate, p.LastActivityDate, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnershipRank
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
    COUNT(DISTINCT ph.Id) AS TotalPosts,
    MAX(ph.LastActivityDate) AS LastPostActivity,
    AVG(ph.Score) AS AvgScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    DENSE_RANK() OVER (ORDER BY AVG(ph.Score) DESC) AS ScoreRank
FROM Users u
LEFT JOIN RecursivePostHierarchy ph ON u.Id = ph.OwnerUserId
LEFT JOIN Posts p ON ph.Id = p.Id
LEFT JOIN Posts t ON POSITION(t.Tags IN p.Tags) <> 0
GROUP BY u.Id, u.DisplayName
HAVING COUNT(DISTINCT ph.Id) > 10 -- Only including users with more than 10 posts
ORDER BY ScoreRank
LIMIT 50;

-- The query includes recursive CTEs to get a hierarchy of posts, joins to gather user details,
-- aggregations to summarize the data, and window functions to rank users by average post score.
