WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS LatestCommentRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
), ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(t.TagName), ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
), HighestScore AS (
    SELECT 
        MAX(Score) AS MaxScore
    FROM 
        RankedPosts
), Benchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        pt.Tags,
        CASE WHEN rp.Score = hs.MaxScore THEN 'Top Post' ELSE 'Regular Post' END AS PostCategory
    FROM 
        RankedPosts rp
    CROSS JOIN 
        HighestScore hs
    LEFT JOIN 
        ProcessedTags pt ON rp.PostId = pt.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerDisplayName,
    CommentCount,
    Tags,
    PostCategory
FROM 
    Benchmark
WHERE 
    CommentCount > 5 -- Filtering posts with more than 5 comments
ORDER BY 
    Score DESC;
