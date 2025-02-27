WITH AggregatedPostData AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    LEFT JOIN
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name(t) ON TRUE
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
FilteredPostData AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Tags,
        CommentCount,
        VoteCount,
        ClosedDate,
        ReopenedDate,
        CASE 
            WHEN ClosedDate IS NOT NULL AND (ReopenedDate IS NULL OR ClosedDate > ReopenedDate) THEN 'Closed'
            WHEN ReopenedDate IS NOT NULL THEN 'Reopened'
            ELSE 'Open'
        END AS PostStatus
    FROM
        AggregatedPostData
)
SELECT
    *,
    CASE 
        WHEN CommentCount > 50 THEN 'Highly Engaged'
        WHEN CommentCount BETWEEN 21 AND 50 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    ROUND((ViewCount::float / NULLIF(VoteCount, 0)) * 100, 2) AS ViewToVoteRatio
FROM
    FilteredPostData
WHERE
    PostStatus = 'Closed'
ORDER BY
    CreationDate DESC
LIMIT 10;
