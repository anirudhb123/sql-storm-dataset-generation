
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_number := 0, @current_user_id := null) AS rn
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*, 
        @overall_rank := @overall_rank + 1 AS OverallRank
    FROM 
        RankedPosts rp,
        (SELECT @overall_rank := 0) AS r
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    tp.OverallRank,
    pht.Name AS PostHistoryType,
    COUNT(DISTINCT ph.Id) AS EditCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.OwnerDisplayName, tp.OverallRank, pht.Name
ORDER BY 
    tp.OverallRank ASC, tp.Score DESC;
