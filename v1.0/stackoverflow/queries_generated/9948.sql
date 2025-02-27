WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    AND p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        Rank
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
)
SELECT 
    tp.*,
    ph.Name AS PostHistoryType,
    ph.CreationDate AS HistoryDate,
    ph.UserDisplayName AS EditorDisplayName
FROM TopPosts tp
LEFT JOIN PostHistory ph ON tp.PostId = ph.PostId 
WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Filters for Title, Body, and Tags edits
ORDER BY tp.Score DESC, tp.ViewCount DESC;
