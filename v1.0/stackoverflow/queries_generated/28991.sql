WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- focusing on Questions and Answers
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- limit to posts in the last year
),
KeywordStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        SUM(LENGTH(p.Body) - LENGTH(REPLACE(p.Body, ' ', '')) + 1) AS WordCount, -- simplistic word count
        SUM(CASE WHEN p.Body LIKE '%interesting%' THEN 1 ELSE 0 END) AS InterestingCount -- keyword finding
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    us.DisplayName AS OwnerDisplayName,
    ks.UniqueTagCount,
    ks.WordCount,
    ks.InterestingCount
FROM 
    RankedPosts rp
JOIN 
    Users us ON rp.OwnerUserId = us.Id
JOIN 
    KeywordStatistics ks ON rp.PostId = ks.PostId
WHERE 
    rp.Rank <= 10 -- give top 10 ranked posts
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
