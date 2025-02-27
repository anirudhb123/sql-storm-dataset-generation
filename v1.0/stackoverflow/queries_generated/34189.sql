WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Base case: Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Depth,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    MAX(p.CreationDate) AS LatestActivity
FROM 
    PostHierarchy ph
LEFT JOIN 
    Comments c ON c.PostId = ph.PostId
LEFT JOIN 
    Votes v ON v.PostId = ph.PostId AND v.VoteTypeId = 8  -- BountyStart
LEFT JOIN 
    Votes v2 ON v2.PostId = ph.PostId AND v2.VoteTypeId = 6  -- Close votes
WHERE 
    v2.Id IS NULL  -- Exclude closed posts
GROUP BY 
    ph.PostId, ph.Title, ph.Depth
HAVING 
    COUNT(c.Id) > 1 OR SUM(v.BountyAmount) > 0
ORDER BY 
    ph.Depth, TotalBounty DESC;

This query uses a recursive CTE to build a hierarchy of posts (primarily questions and their answers). It collects information on the number of comments, total bounties awarded, and the latest activity date for each question in the hierarchy, while excluding closed posts. The final results are sorted by the depth of the posts and the total bounty amount.
