
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        CHAR_LENGTH(TRIM(BOTH '<>' FROM p.Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM p.Tags), '>', '')) AS TagCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.TagCount,
    ph.Comment AS EditHistoryComment,
    ph.CreationDate AS EditHistoryDate,
    ph.UserDisplayName AS EditorName
FROM RankedPosts rp
LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
WHERE rp.Rank <= 5 AND ph.PostHistoryTypeId IN (4, 5, 6)  
ORDER BY rp.Rank;
