WITH RecursiveCTE AS (
    -- CTE to find the tag names of posts where the number of answers is greater than the average
    SELECT 
        Tags,
        COUNT(*) AS AnswerCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        Tags
    HAVING 
        COUNT(*) > (SELECT AVG(AnswerCount) 
                     FROM (SELECT COUNT(*) AS AnswerCount 
                           FROM Posts 
                           WHERE PostTypeId = 2 -- Only Answers
                           GROUP BY ParentId) AS SubQuery)
    
    UNION ALL
    
    SELECT 
        p.Tags,
        COUNT(c.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Tags
),
FilteredPosts AS (
    -- CTE to filter posts that have a score above a certain threshold and are not closed
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(c.ClosedDate, '9999-12-31') AS ClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, ClosedDate 
         FROM Posts 
         WHERE ClosedDate IS NOT NULL) c ON p.Id = c.PostId
    WHERE 
        p.Score > 10 AND 
        p.PostTypeId = 1 AND 
        (c.ClosedDate IS NULL OR c.ClosedDate > CURRENT_TIMESTAMP)
),
RankedPosts AS (
    -- CTE for ranking posts based on score and number of comments
    SELECT 
        fp.Id,
        fp.Title,
        fp.Score,
        DENSE_RANK() OVER (ORDER BY fp.Score DESC, c.CommentCount DESC) AS Rank
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON fp.Id = c.PostId
)
SELECT 
    u.DisplayName AS UserName,
    p.Title,
    p.Score,
    COALESCE(b.Name, 'No Badge') AS Badge,
    RANK() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.Rank <= 10
ORDER BY 
    p.Rank;
