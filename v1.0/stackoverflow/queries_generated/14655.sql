-- Performance benchmarking query for Stack Overflow schema
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    CommentCount,
    VoteCount,
    UpVotes,
    DownVotes
FROM 
    PostStats
WHERE 
    RowNum <= 100  -- Limit to the latest 100 posts for benchmarking
ORDER BY 
    ViewCount DESC;  -- Order by view count for performance insight
