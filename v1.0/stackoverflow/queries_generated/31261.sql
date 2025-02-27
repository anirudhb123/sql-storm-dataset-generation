WITH RecursivePostHierarchy AS (
    -- CTE to recursively find the hierarchy of posts (answers to questions)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        1 AS Level,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        Level + 1,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS EditCount,
    AVG(CASE WHEN ph.UserId IS NOT NULL THEN DATEDIFF(SECOND, ph.CreationDate, CURRENT_TIMESTAMP) ELSE NULL END) AS AvgTimeToEdit,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tags edited
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3, 8)  -- Upvotes, Downvotes, Bounty Starts
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5 AND 
    SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) > 0
ORDER BY 
    TotalPosts DESC, TotalBounty DESC;
