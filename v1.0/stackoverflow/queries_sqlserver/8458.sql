
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        u.Reputation,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Reputation,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    ORDER BY 
        rp.Score DESC, 
        rp.ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Reputation,
    tp.CommentCount,
    pt.Name AS PostType
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON (tp.AnswerCount > 1 AND tp.Score > 10) 
WHERE 
    tp.ViewCount > 1000
ORDER BY 
    tp.Reputation DESC,
    tp.CreationDate DESC;
