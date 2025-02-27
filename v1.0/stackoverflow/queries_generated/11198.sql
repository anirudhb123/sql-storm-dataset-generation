-- Performance benchmarking query for the Stack Overflow schema

-- This query will analyze user engagement by calculating the average score of posts 
-- along with the total number of comments and votes for a specific user.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(AVG(p.Score), 0) AS AvgPostScore,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- This query provides a summary of post activity by type to understand which post type
-- has the highest engagement in terms of scores and views.
SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    TotalViews DESC;

-- This benchmark query assesses the trending tags based on their usage in posts
-- along with the average score of those posts to identify popular topics of discussion.
SELECT 
    t.TagName,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(AVG(p.Score), 0) AS AvgPostScore
FROM 
    Tags t
LEFT JOIN 
    Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
GROUP BY 
    t.TagName
ORDER BY 
    TotalPosts DESC;
