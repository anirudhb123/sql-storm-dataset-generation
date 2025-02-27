
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        @rn := IF(@prevUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevUserId := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @rn := 0, @prevUserId := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
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
    LIMIT 10
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
