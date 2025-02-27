WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN a.Score > 0 THEN 1 ELSE 0 END) AS PositiveAnswers,
        AVG(a.Score) AS AverageAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
TagStats AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    as.AnswerCount,
    as.PositiveAnswers,
    as.AverageAnswerScore,
    ts.Tags
FROM 
    RecentPosts rp
LEFT JOIN 
    AnswerStats as ON rp.Id = as.PostId
LEFT JOIN 
    TagStats ts ON rp.Id = ts.PostId
WHERE 
    (rp.ViewCount > 50 OR as.AnswerCount > 0)
    AND rp.rn = 1
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
LIMIT 100;
