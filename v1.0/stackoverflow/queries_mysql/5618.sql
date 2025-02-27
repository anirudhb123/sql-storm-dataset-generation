
WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
RecentPostHistories AS (
    SELECT ph.PostId,
           ph.CreationDate AS HistoryDate,
           p.Title,
           ph.UserDisplayName,
           ph.Comment,
           ph.Text,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13) 
      AND ph.CreationDate > NOW() - INTERVAL 30 DAY
),
PostTags AS (
    SELECT p.Id AS PostId,
           GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS Tag
        FROM Posts p
        JOIN (SELECT a.N + b.N * 10 + 1 n
              FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                    UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                   (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                    UNION ALL SELECT 8 UNION ALL SELECT 9) b
              ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    ) AS tag ON true
    JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id
)
SELECT rp.Id AS PostId,
       rp.Title,
       rp.CreationDate,
       rp.Score,
       rp.ViewCount,
       rp.OwnerDisplayName,
       COALESCE(pt.Tags, 'No Tags') AS Tags,
       CASE WHEN rph.HistoryRank IS NOT NULL THEN rph.HistoryDate END AS LastHistoryDate,
       CASE WHEN rph.HistoryRank IS NOT NULL THEN rph.Comment END AS LastComment,
       CASE WHEN rph.HistoryRank IS NOT NULL THEN rph.Text END AS LastText
FROM RankedPosts rp
LEFT JOIN RecentPostHistories rph ON rp.Id = rph.PostId AND rph.HistoryRank = 1
LEFT JOIN PostTags pt ON rp.Id = pt.PostId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.CreationDate DESC;
