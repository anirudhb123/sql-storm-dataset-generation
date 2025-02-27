
WITH PostSummary AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        JSON_TABLE(JSON_ARRAYAGG(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1))) 
        ORDER BY n.n) AS tag ON TRUE
    LEFT JOIN
        Tags t ON tag = t.TagName
    CROSS JOIN 
        (SELECT @rownum := @rownum + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
        UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t, 
        (SELECT @rownum := 0) r) n
    WHERE
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY
        p.Id, u.DisplayName, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT
        tp.*, 
        @rank := IF(@prev_score = tp.Score, @rank + 1, 1) AS ScoreRank,
        @prev_score := tp.Score
    FROM
        PostSummary tp
    CROSS JOIN (SELECT @prev_score := NULL, @rank := 0) r
),
PostHistoryAggregates AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS EditHistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.UserId END) AS UniqueClosers
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.Tags,
    pha.EditHistoryCount,
    pha.LastClosedDate,
    pha.UniqueClosers,
    CASE 
        WHEN pha.EditHistoryCount > 5 THEN 'Highly Edited'
        WHEN pha.UniqueClosers > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE WHEN tp.ScoreRank <= 10 AND tp.Score > 0 THEN 'Top Score' ELSE 'Standard' END AS ScoreCategory
FROM
    TopPosts tp
LEFT JOIN
    PostHistoryAggregates pha ON tp.PostId = pha.PostId
ORDER BY
    tp.Score DESC, tp.ViewCount DESC
LIMIT 50;
