WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0
        ) AS UpvoteCount,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0
        ) AS DownvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.ScoreRank,
    pt.Tags,
    COALESCE(cp.FirstClosedDate, 'NO CLOSED DATE') AS FirstClosedDate,
    rp.UpvoteCount,
    rp.DownvoteCount,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreSentiment,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top post in category'
        WHEN rp.ScoreRank <= 3 THEN 'Top 3 post in category'
        ELSE 'Lower Ranked Post'
    END AS RankDescription
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.UpvoteCount - rp.DownvoteCount) > 10
    OR rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
