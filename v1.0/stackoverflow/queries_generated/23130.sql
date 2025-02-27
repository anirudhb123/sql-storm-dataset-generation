WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AverageScores AS (
    SELECT 
        OwnerUserId,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerDisplayName,
    COALESCE(c.CloseCount, 0) AS CloseCount,
    COALESCE(a.AvgScore, 0) AS OwnerAvgScore,
    CASE 
        WHEN r.RN = 1 THEN 'Most Recent Post'
        WHEN r.ViewCount > 1000 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN r.Score IS NOT NULL AND r.Score > 0 THEN 'Positive'
        WHEN r.Score IS NULL THEN 'No Score'
        ELSE 'Negative'
    END AS ScoreStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    RecursiveCTE r
LEFT JOIN 
    ClosedPosts c ON r.PostId = c.PostId
LEFT JOIN 
    AverageScores a ON r.OwnerUserId = a.OwnerUserId
LEFT JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.OwnerDisplayName, r.RN, r.ViewCount, r.Score
ORDER BY 
    r.ViewCount DESC
LIMIT 100;
