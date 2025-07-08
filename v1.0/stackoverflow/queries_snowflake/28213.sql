
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY ARRAY_AGG(tag.TagName) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        LATERAL FLATTEN(input => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS tag
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        Score,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS OverallRank
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score
FROM 
    TopPosts tp
JOIN 
    (SELECT 
        COUNT(*) AS TotalQuestions,
        AVG(ViewCount) AS AvgViewCount
     FROM 
        RankedPosts) stats ON TRUE
ORDER BY 
    tp.OverallRank
LIMIT 10;
