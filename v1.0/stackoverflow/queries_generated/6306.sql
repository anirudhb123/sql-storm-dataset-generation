WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostID,
        Title,
        Score,
        CreationDate,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    ph.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostID = ph.PostId
GROUP BY 
    tp.PostID, tp.Title, tp.Score, tp.CreationDate, tp.ViewCount, tp.OwnerDisplayName, ph.Name
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
