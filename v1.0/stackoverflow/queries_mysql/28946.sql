
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
        LEFT JOIN (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
            FROM 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
                 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            WHERE 
                CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) t ON true
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Body, p.Title, p.CreationDate
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ClosedPostStats AS (
    SELECT 
        r.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.HistoryCount ELSE 0 END) AS CloseCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.HistoryCount ELSE 0 END) AS ReopenCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.HistoryCount ELSE 0 END) AS DeleteCount
    FROM 
        RankedPosts r
    LEFT JOIN PostHistoryStats ph ON r.PostId = ph.PostId
    GROUP BY 
        r.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    cps.CloseCount,
    cps.ReopenCount,
    cps.DeleteCount
FROM 
    RankedPosts rp
LEFT JOIN ClosedPostStats cps ON rp.PostId = cps.PostId
WHERE 
    cps.CloseCount > 0 
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC;
