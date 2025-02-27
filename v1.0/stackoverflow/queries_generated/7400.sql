WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    COALESCE(ARRAY_AGG(DISTINCT c.Text) FILTER (WHERE c.Text IS NOT NULL), '{}') AS Comments,
    ARRAY_AGG(DISTINCT b.Name) AS BadgesEarned
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = tp.OwnerDisplayName)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.AnswerCount, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
