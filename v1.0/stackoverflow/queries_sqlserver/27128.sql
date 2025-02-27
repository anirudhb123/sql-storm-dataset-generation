
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1 
    ORDER BY 
        Score DESC, ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    STRING_AGG(DISTINCT value, ', ') AS ParsedTags
FROM 
    TopPosts tp
CROSS APPLY STRING_SPLIT(tp.Tags, '><') AS value
LEFT JOIN Users u ON u.Id IN (SELECT DISTINCT c.UserId FROM Comments c WHERE c.PostId = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.VoteCount
ORDER BY 
    tp.Score DESC;
