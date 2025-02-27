WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsAggregated
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (
            SELECT DISTINCT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
        ) t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryCreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryTotalCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > (SELECT MIN(CreationDate) FROM Posts)
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate AS PostCreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        rp.VoteCount,
        rp.TagsAggregated,
        ph.HistoryType,
        ph.HistoryCreationDate,
        ph.HistoryRank,
        ph.HistoryTotalCount,
        CASE 
            WHEN ph.HistoryTotalCount > 5 THEN 'Multiple Changes'
            WHEN ph.HistoryRank = 1 AND ph.HistoryTotalCount = 1 THEN 'First History Entry'
            ELSE 'Other'
        END AS HistoryCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
)
SELECT 
    *,
    CASE 
        WHEN ViewCount IS NULL THEN 'Views not available'
        ELSE CONCAT('Views: ', ViewCount)
    END AS ViewCountInfo,
    COALESCE(NULLIF(HistoryType, 'Post Deleted'), 'Active Post') AS PostStatus
FROM 
    FinalResults
WHERE 
    ScoreRank <= 10
ORDER BY 
    CreationDate DESC, Score DESC
FETCH FIRST 50 ROWS ONLY;
