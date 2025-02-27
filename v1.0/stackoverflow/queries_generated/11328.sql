-- Performance benchmarking query to analyze post activity and user engagement in the Stack Overflow schema

WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Count Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Count Downvotes
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Only consider posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.AnswerCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.CommentCount,
    pa.EditCount,
    (CASE 
        WHEN pa.AnswerCount > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END) AS ActivityStatus  -- Categorize activity based on answer count
FROM 
    PostAnalytics pa
ORDER BY 
    pa.ViewCount DESC,  -- Order by view count for benchmarking
    pa.Score DESC;      -- Then by score for relevance
