
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.CreationDate > '2020-01-01' AND p.Score > 10
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        @overall_rank := @overall_rank + 1 AS OverallRank
    FROM 
        RankedPosts rp
    CROSS JOIN (SELECT @overall_rank := 0) AS vars
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.OverallRank
FROM 
    TopPosts tp
JOIN 
    Votes v ON tp.PostId = v.PostId
WHERE 
    v.CreationDate > '2023-01-01' AND v.VoteTypeId IN (2, 3) 
ORDER BY 
    tp.OverallRank, tp.ViewCount DESC;
