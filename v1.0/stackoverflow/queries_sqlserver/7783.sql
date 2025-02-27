
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.OwnerUserId
), RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -3, '2024-10-01 12:34:56')
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    ra.HistoryDate,
    ra.EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
