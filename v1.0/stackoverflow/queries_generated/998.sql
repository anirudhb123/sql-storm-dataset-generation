WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.OwnerRank <= 5
),
PostHistoryDetails AS (
    SELECT 
        h.PostId,
        GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name SEPARATOR ', ') AS HistoryTypes
    FROM PostHistory h
    JOIN PostHistoryTypes pt ON h.PostHistoryTypeId = pt.Id
    GROUP BY h.PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    COALESCE(ph.HistoryTypes, 'No history') AS HistoryDetails
FROM TopPosts tp
LEFT JOIN PostHistoryDetails ph ON tp.Id = ph.PostId
ORDER BY tp.Score DESC, tp.CreationDate DESC;
