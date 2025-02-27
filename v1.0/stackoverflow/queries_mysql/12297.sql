
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        @row_number := @row_number + 1 AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN 
        (SELECT @row_number := 0) AS r
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
    ORDER BY 
        p.CreationDate DESC
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CreationDate,
    Score,
    CommentCount,
    VoteCount
FROM 
    RankedPosts
WHERE 
    RowNum <= 100;
