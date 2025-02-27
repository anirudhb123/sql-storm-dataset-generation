WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AnswerMetrics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AverageAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankScore,
    am.AnswerCount,
    am.AverageAnswerScore,
    phc.EditCount,
    phc.LastEditDate,
    phc.ChangeTypes,
    rp.TagCount,
    CASE 
        WHEN rp.RankScore > 10 THEN 'High Score'
        WHEN rp.RankScore BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    AnswerMetrics am ON rp.PostId = am.PostId
LEFT JOIN 
    PostHistoryChanges phc ON rp.PostId = phc.PostId
WHERE 
    rp.TagCount > 2
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC
LIMIT 100;
This SQL query gathers insights from the StackOverflow schema about posts created in the last year, ranking them based on their score, calculating the number of answers and average answer scores, and summarizing edit history. It has multiple CTEs, joins, and complex aggregations, making it suitable for performance benchmarking.
