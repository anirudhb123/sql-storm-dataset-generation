WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_names(tag) 
    ON TRUE
    LEFT JOIN Tags t ON t.TagName = tag_names.tag
    WHERE p.PostTypeId = 1 AND p.Score > 0
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.Tags,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Contributor'
        WHEN rp.Rank BETWEEN 6 AND 10 THEN 'Moderate Contributor'
        ELSE 'Needs Improvement'
    END AS ContributorLevel
FROM RankedPosts rp
WHERE rp.CommentCount > 0
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Comment AS EditComment,
        ph.Text AS OldValue,
        ph.UserDisplayName || ' edited this post on ' || to_char(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS EditDetails
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, or Edit Tags
    ORDER BY ph.CreationDate DESC
    LIMIT 50
)

SELECT 
    ra.PostId,
    ra.PostTitle,
    ra.Editor,
    ra.EditDate,
    ra.EditComment,
    ra.EditDetails,
    COALESCE(NULLIF(REGEXP_REPLACE(ra.OldValue, '<[^>]+>', ''), ''), 'No Change') AS CleanedOldValue
FROM RecentActivity ra
ORDER BY ra.EditDate DESC;

