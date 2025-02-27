WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) as CommentCount,
        AVG(v.VoteTypeId) OVER (PARTITION BY p.Id) as AvgVoteType, 
        STRING_AGG(DISTINCT t.TagName, ', ') OVER (PARTITION BY p.Id) AS TagList
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '>')) AS TagName 
    ) t ON TRUE
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),

ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId
),

CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ScoreRank,
        rp.CommentCount,
        cp.CloseCount,
        cp.CloseReasons,
        rp.TagList,
        CASE
            WHEN cp.CloseCount IS NULL THEN 'Open'
            ELSE 'Closed'
        END AS PostStatus,
        CASE 
            WHEN rp.AvgVoteType IS NULL THEN 'No Votes'
            WHEN rp.AvgVoteType >= 3 THEN 'Positive Feedback'
            ELSE 'Mixed or Negative Feedback'
        END AS FeedbackStatus
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    PostId, 
    Title,
    CreationDate,
    Score,
    ScoreRank,
    CommentCount,
    CloseCount,
    CloseReasons,
    TagList,
    PostStatus,
    FeedbackStatus
FROM CombinedData
WHERE Score > 10 OR CloseCount > 0
ORDER BY Score DESC, CreationDate ASC
LIMIT 100;

-- Bonus analysis: Calculate the standard deviation of scores of closed posts for insight.
SELECT 
    STDDEV(SCORE) AS ScoreStdDev
FROM CombinedData
WHERE PostStatus = 'Closed';
