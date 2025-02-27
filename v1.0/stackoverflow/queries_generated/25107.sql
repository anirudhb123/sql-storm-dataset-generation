WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN Posts.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosed
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '>')::int[])
    GROUP BY 
        Tags.TagName
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ts.TagName,
    ts.TotalPosts,
    ts.TotalQuestions,
    ts.TotalAnswers,
    ts.TotalClosed,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    AVG(p.ViewCount) AS AvgViews,
    COUNT(DISTINCT p.Id) AS TotalPostsAuthored,
    COUNT(DISTINCT c.Id) AS TotalCommentsMade
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
JOIN 
    TagStatistics ts ON ts.TotalPosts > 10 -- Only consider tags with more than 10 related posts
GROUP BY 
    u.Id, ts.TagName
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Users should have authored more than 5 posts
ORDER BY 
    u.Reputation DESC, ts.TotalPosts DESC
LIMIT 50; -- Limiting the result for benchmarking purposes
