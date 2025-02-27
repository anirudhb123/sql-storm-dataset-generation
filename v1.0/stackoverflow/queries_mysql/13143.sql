
SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPostsCount,
    DATE_FORMAT(p.CreationDate, '%Y-%m-01') AS month
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-10-01 12:34:56' 
GROUP BY 
    DATE_FORMAT(p.CreationDate, '%Y-%m-01')
ORDER BY 
    DATE_FORMAT(p.CreationDate, '%Y-%m-01');
