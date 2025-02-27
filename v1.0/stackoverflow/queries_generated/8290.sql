WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.WikiPostId = p.Id) AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.ScoreRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.Tags,
    COALESCE(MAX(ph.CreationDate), 'No Edits') AS LastEditDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.CommentCount, tp.AnswerCount, tp.Tags
ORDER BY 
    tp.Score DESC;
