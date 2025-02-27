WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Tags,
           p.Score,
           p.CreationDate,
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankWithinTag
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Filtering only questions
      AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
    GROUP BY p.Id, p.Title, p.Tags, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT rp.*, 
           ARRAY_AGG(DISTINCT t.TagName) AS UniqueTags
    FROM RankedPosts rp
    JOIN LATERAL (
        SELECT unnest(string_to_array(rp.Tags, '><')) AS TagName
    ) t ON TRUE
    WHERE rp.RankWithinTag <= 5 -- Top 5 posts by score per tag
    GROUP BY rp.PostId, rp.Title, rp.Tags, rp.Score, rp.CreationDate, rp.RankWithinTag
),
PostHistoryCounts AS (
    SELECT ph.PostId,
           COUNT(*) AS HistoryChanges
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT tp.PostId,
       tp.Title,
       tp.Score,
       tp.CommentCount,
       tp.CreationDate,
       tp.UniqueTags,
       COALESCE(phc.HistoryChanges, 0) AS HistoryChanges
FROM TopPosts tp
LEFT JOIN PostHistoryCounts phc ON tp.PostId = phc.PostId
ORDER BY tp.Score DESC, tp.CommentCount DESC;

This SQL query retrieves the top five questions by score in the last year, grouped by their tags, and also counts the number of edits made to each post. It aggregates distinct tags of each post and provides a comprehensive overview of popular questions and their edit history.
