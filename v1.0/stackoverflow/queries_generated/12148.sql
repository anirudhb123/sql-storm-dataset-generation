-- Performance Benchmarking Query for StackOverflow Schema

-- This query will retrieve a summary of post statistics along with user involvement, focusing on the most common post types.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS UserCreatedPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.CommentCount) AS TotalComments,
    SUM(p.FavoriteCount) AS TotalFavorites
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Benchmarking on Users Engagement with Posts

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    AVG(COALESCE(p.Score, 0)) AS AveragePostScore,
    SUM(p.ViewCount) AS TotalPostViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- Performance check on Post History

SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS TotalHistoryRecords,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ph.CreationDate)) / 3600) AS AverageHoursSinceLastEdit
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalHistoryRecords DESC;
