-- Performance Benchmarking Query

-- This query retrieves summary statistics from the Posts table, 
-- joining with Users and PostTypes to get additional context,
-- while also evaluating how many posts exist for each PostType.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT p.OwnerUserId) AS TotalAuthors,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments,
    SUM(p.FavoriteCount) AS TotalFavorites,
    MAX(p.CreationDate) AS MostRecentPost,
    MIN(p.CreationDate) AS OldestPost
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
