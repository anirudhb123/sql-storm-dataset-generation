WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId IN (1, 2) -- Including only Questions (1) and Answers (2)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Author,
        rp.CreationDate,
        rp.Score
    FROM RankedPosts rp
    WHERE rp.Rank <= 5 -- Get Top 5 Posts by Score for each Post Type
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
FinalPostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Author,
        tp.CreationDate,
        tp.Score,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
    FROM TopPosts tp
    LEFT JOIN PostComments pc ON tp.PostId = pc.PostId
    LEFT JOIN LATERAL (
        SELECT 
            UNNEST(STRING_TO_ARRAY(SUBSTRING(tp.Tags, 2, LENGTH(tp.Tags) - 2), '><')) AS TagName
    ) t ON TRUE 
    GROUP BY tp.PostId, tp.Title, tp.Author, tp.CreationDate, tp.Score
)

SELECT 
    metrics.PostId,
    metrics.Title,
    metrics.Author,
    metrics.CreationDate,
    metrics.Score,
    metrics.TotalComments,
    metrics.RelatedTags,
    pht.Name AS PostHistoryType
FROM FinalPostMetrics metrics
LEFT JOIN PostHistory ph ON ph.PostId = metrics.PostId
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY metrics.Score DESC, metrics.CreationDate DESC;
