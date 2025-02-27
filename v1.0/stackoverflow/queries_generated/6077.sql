WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
)

SELECT 
    r.PostId, 
    r.Title, 
    r.CreationDate, 
    r.Score, 
    r.ViewCount, 
    r.AnswerCount, 
    r.CommentCount, 
    r.OwnerDisplayName,
    ph.TypeName AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    RankedPosts r
LEFT JOIN 
    PostHistory ph ON r.PostId = ph.PostId 
WHERE 
    r.Rank <= 5
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount, r.AnswerCount, r.CommentCount, r.OwnerDisplayName, ph.TypeName
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
