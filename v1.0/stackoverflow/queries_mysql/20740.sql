
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        p.AcceptedAnswerId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
DetailedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        PHT.Name AS PostHistoryTypeName
    FROM PostHistory ph
    JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE ph.CreationDate > NOW() - INTERVAL 1 YEAR
),
DistinctTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList
    FROM Posts p
    LEFT JOIN (
        SELECT 
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM Posts p
        JOIN (
            SELECT 
                1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON t.Id = p.Id
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    dt.TagsList,
    dph.HistoryDate,
    dph.UserDisplayName,
    dph.Comment,
    dph.Text,
    dph.PostHistoryTypeName,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 
            (SELECT Title FROM Posts WHERE Id = rp.AcceptedAnswerId)
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerTitle
FROM RankedPosts rp
LEFT JOIN DistinctTags dt ON rp.PostId = dt.PostId
LEFT JOIN DetailedPostHistory dph ON rp.PostId = dph.PostId 
WHERE rp.PostRank = 1 
AND (rp.ViewCount > 100 OR dt.TagsList IS NOT NULL)
ORDER BY rp.CreationDate DESC
LIMIT 50;
