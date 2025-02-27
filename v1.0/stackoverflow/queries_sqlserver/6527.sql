
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE)
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10;
