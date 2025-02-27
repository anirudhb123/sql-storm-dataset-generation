WITH RecursivePostCTE AS (
    -- This CTE generates a hierarchy of posts, starting from the main questions
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Fetching only questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
)
SELECT 
    p.PostId,
    p.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
    MAX(ph.UserDisplayName) AS LastEditor 
FROM 
    RecursivePostCTE p
LEFT JOIN 
    Comments c ON p.PostId = c.PostId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId
LEFT JOIN 
    PostHistory ph ON p.PostId = ph.PostId 
WHERE 
    p.Level = 1  -- Only top-level questions
GROUP BY 
    p.PostId, p.Title
HAVING 
    COUNT(DISTINCT c.Id) > 0  -- Only questions that have comments
ORDER BY 
    Upvotes DESC, 
    Downvotes ASC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; 

-- Note: This query retrieves the top 10 questions with comments, along with their upvote/downvote statistics, their closed status, and last editor information.
