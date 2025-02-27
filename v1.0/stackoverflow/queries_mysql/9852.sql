
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @rank := IF(@prev_post_type = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @rank := 0, @prev_post_type := NULL) r
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        @overall_rank := @overall_rank + 1 AS OverallRank
    FROM 
        RankedPosts rp
    CROSS JOIN (SELECT @overall_rank := 0) r
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OverallRank
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId = pt.Id
WHERE 
    pt.Name IN ('Question', 'Answer')
ORDER BY 
    tp.OverallRank;
