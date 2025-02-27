
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
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
               SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score
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
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11, 12)  
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
