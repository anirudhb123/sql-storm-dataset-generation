WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON tag::varchar = t.TagName
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        pht.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11, 12)  -- Edited Title, Body, Tags, Close, Reopen, Delete
),
FinalBenchmarkResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.Tags,
        COUNT(phc.PostId) AS ChangeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryChanges phc ON rp.PostId = phc.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.Tags
)
SELECT 
    *,
    CASE 
        WHEN ChangeCount > 3 THEN 'Highly Edited'
        WHEN ChangeCount > 0 THEN 'Moderately Edited'
        ELSE 'No Changes'
    END AS EditStatus
FROM 
    FinalBenchmarkResults
ORDER BY 
    Score DESC, ViewCount DESC, CreationDate ASC
LIMIT 100;
