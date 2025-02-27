
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName 
         FROM Posts p JOIN (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1) AS tag 
    ON tag.TagName IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END) AS DeleteUndeleteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 2 THEN 1 ELSE 0 END) AS InitialBodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.VoteCount,
    rp.Tags,
    ph.CloseReopenCount,
    ph.DeleteUndeleteCount,
    ph.InitialBodyEdits
FROM 
    RankedPosts rp
JOIN 
    PostHistoryStats ph ON rp.PostId = ph.PostId
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC,
    rp.CreationDate ASC
LIMIT 100;
