WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Only last year's posts
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.PostTypeName,
    ISNULL(comments.CommentCount, 0) AS TotalComments,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = r.PostId 
       AND v.VoteTypeId IN (2, 3)) AS TotalVotes, -- Upvotes and Downvotes
    (SELECT STRING_AGG(DISTINCT b.Name, ', ') 
     FROM Badges b 
     WHERE b.UserId = u.Id) AS UserBadges
FROM 
    RankedPosts r
LEFT JOIN 
    Users u ON r.PostId = u.Id -- This is a corner case to link Posts by creator
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) comments ON r.PostId = comments.PostId
WHERE 
    r.RankByScore <= 5 -- Top 5 by score for each post type
    AND u.Reputation IS NOT NULL
ORDER BY 
    CASE 
        WHEN r.PostTypeName = 'Question' THEN 1
        WHEN r.PostTypeName = 'Answer' THEN 2
        ELSE 3 
    END,
    r.Score DESC,
    r.CreationDate DESC
OPTION (RECOMPILE);

This SQL query constructs a Common Table Expression (CTE) `RankedPosts` which ranks posts based on their score and date. It retrieves users' profile details and their badges, totals comments on the top 5 posts by score per post type, and calculates the total votes (upvotes and downvotes). The outer query selects specific fields, applying various joins and filtering criteria, including null checks and aggregate functions, showcasing complex SQL constructs and optimizing the execution plan with an `OPTION (RECOMPILE)` hint for dynamic performance benchmarking.
