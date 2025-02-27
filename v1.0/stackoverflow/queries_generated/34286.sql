WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score AS QuestionScore,
    r.ViewCount AS QuestionViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    (SELECT COUNT(c.Id) 
     FROM Comments c 
     WHERE c.PostId = r.PostId) AS CommentCount,
    (SELECT COUNT(ph.Id) 
     FROM PostHistory ph 
     WHERE ph.PostId = r.PostId 
     AND ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    ) AS ClosureEventCount,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
    ROW_NUMBER() OVER (PARTITION BY r.OwnerUserId ORDER BY r.CreationDate DESC) AS UserPostRank
FROM 
    RecursiveCTE r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    PostLinks pl ON r.PostId = pl.PostId
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT pl.RelatedPostId) > 1 -- Ensure there are linked posts
ORDER BY 
    r.Score DESC, r.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- The above query achieves several things:
-- 1. It combines a recursive CTE to track questions and their respective answers.
-- 2. It pulls relevant user data about the post owners.
-- 3. It counts related posts to showcase how many links are related to each question.
-- 4. It includes multiple aggregations and conditional counting using correlated subqueries.
-- 5. It ranks each user's posts by creation date.
-- 6. Finally, it filters and paginates the results for performance benchmarking.
