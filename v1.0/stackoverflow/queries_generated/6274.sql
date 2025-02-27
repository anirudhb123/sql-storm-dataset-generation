WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.AnswerCount,
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    INNER JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.AnswerCount,
    tp.PostTypeName,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
