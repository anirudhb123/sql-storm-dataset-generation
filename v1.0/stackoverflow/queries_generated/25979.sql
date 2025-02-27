WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        pm.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankPerTag
    FROM 
        Posts p
    JOIN 
        Users pm ON p.OwnerUserId = pm.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
), 
TagStatistics AS (
    SELECT 
        STRING_AGG(DISTINCT TRIM(UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))), ', ') AS Tags,
        COUNT(*) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS MostRecent
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Tags
)
SELECT 
    ts.Tags,
    ts.TotalPosts,
    ts.AvgScore,
    ts.MostRecent,
    rp.Title,
    rp.Body,
    rp.CreationDate AS TopPostDate,
    rp.Score AS TopPostScore,
    rp.Reputation AS OwnerReputation
FROM 
    TagStatistics ts
JOIN 
    RankedPosts rp ON STRING_AGG(DISTINCT TRIM(UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))), ', ') = ts.Tags
WHERE 
    ts.TotalPosts > 10 -- Only consider tags with more than 10 posts
ORDER BY 
    ts.AvgScore DESC, 
    ts.TotalPosts DESC
LIMIT 10;
