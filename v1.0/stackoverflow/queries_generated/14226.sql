-- Performance Benchmarking Query
-- This query aggregates post statistics for analysis of performance in terms of creation and activity on posts.

SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    AVG(COALESCE(p.ViewCount, 0)) AS AverageViewsPerPost,
    AVG(COALESCE(p.Score, 0)) AS AverageScorePerPost,
    COUNT(c.Id) AS TotalComments,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount,
    COUNT(DISTINCT b.Id) AS TotalBadgesAwarded
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Only count bounty start and close votes
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for the last year
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;
