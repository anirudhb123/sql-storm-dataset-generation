-- Performance Benchmarking SQL Query

-- This query benchmarks the performance by selecting posts with their associated users,
-- counting the number of votes they received, and summarizing their associated comments
-- within a specific time frame to analyze the effectiveness of posts.
 
WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id
),
PostCommentCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(pvc.VoteCount, 0) AS VoteCount,
    COALESCE(pcc.CommentCount, 0) AS CommentCount,
    p.Score,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteCounts pvc ON p.Id = pvc.PostId
LEFT JOIN 
    PostCommentCounts pcc ON p.Id = pcc.PostId
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
ORDER BY 
    p.Score DESC, VoteCount DESC, CommentCount DESC;

-- This query retrieves posts created in the last year, their associated owner user, votes and comments counts,
-- and sorts them predominantly by their score, then by the vote count and comment count, thus showing the most popular posts first.
