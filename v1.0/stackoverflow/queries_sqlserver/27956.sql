
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        STRING_SPLIT(p.Tags, '>') AS tag ON tag.value IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 2 THEN 1 END) AS InitialBodyEdits
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
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
