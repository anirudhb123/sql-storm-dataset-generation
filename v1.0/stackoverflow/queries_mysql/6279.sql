
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        @ScoreRank := IF(@prevScore = p.Score, @ScoreRank, @ScoreRank + 1) AS ScoreRank,
        @prevScore := p.Score
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    CROSS JOIN (SELECT @ScoreRank := 0, @prevScore := NULL) AS vars
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        @RN := @RN + 1 AS RN
    FROM 
        RankedPosts rp
    CROSS JOIN (SELECT @RN := 0) AS rn_vars
    WHERE 
        rp.ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.Location AS OwnerLocation
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.Id = u.Id
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
