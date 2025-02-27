
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (SELECT a.N + b.N * 10 AS n
          FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
               (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    WHERE n.n > 0 AND n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    AND PostTypeId = 1 
    GROUP BY Tag
),
RecentEdits AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Comment AS EditComment,
        ph.Text AS NewValue,
        @row_num := IF(@prev_id = p.Id, @row_num + 1, 1) AS EditRank,
        @prev_id := p.Id
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    CROSS JOIN (SELECT @row_num := 0, @prev_id := NULL) r
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
    ORDER BY p.Id, ph.CreationDate DESC
),
EditorStats AS (
    SELECT 
        Editor,
        COUNT(DISTINCT PostId) AS TotalEditedPosts,
        MIN(EditDate) AS FirstEditDate,
        MAX(EditDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM RecentEdits
    WHERE EditRank = 1 
    GROUP BY Editor
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
)
SELECT 
    e.Editor,
    e.TotalEditedPosts,
    e.FirstEditDate,
    e.LastEditDate,
    e.EditCount,
    tt.Tag,
    tt.PostCount
FROM EditorStats e
JOIN TopTags tt ON e.EditCount > 5 
WHERE tt.TagRank <= 10 
ORDER BY e.EditCount DESC, tt.PostCount DESC;
