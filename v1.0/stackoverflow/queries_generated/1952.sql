WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL) OVER (PARTITION BY p.Id) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.CreationDate,
    rp.Rank,
    ph.LastEditDate,
    ph.HistoryCount,
    CASE 
        WHEN rp.UpVoteCount - rp.DownVoteCount > 0 THEN 'Positive'
        WHEN rp.UpVoteCount - rp.DownVoteCount < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN rp.UpVoteCount + rp.DownVoteCount = 0 THEN NULL 
        ELSE (rp.UpVoteCount::float / (rp.UpVoteCount + rp.DownVoteCount)) * 100 
    END AS UpvotePercentage
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
