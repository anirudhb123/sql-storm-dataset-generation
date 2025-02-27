WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Only consider Questions (1) and Answers (2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '> <'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) >= 10  -- Only popular tags used in 10 or more posts
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount  -- Count of Close actions
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.RankByScore,
    rp.CommentCount,
    pht.LastEditDate,
    pht.CloseCount,
    pht.HistoryTypes,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails pht ON rp.PostId = pht.PostId
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT UNNEST(string_to_array(rp.Tags, '> <')))
WHERE 
    rp.RankByScore <= 3  -- Top 3 posts per user
    AND (rp.Score > 5 OR rp.CommentCount > 3)  -- Filtering posts with sufficient engagement
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 100;  -- Return top 100 posts

This SQL query demonstrates various advanced SQL features, including Common Table Expressions (CTEs), window functions, outer joins, aggregation, filtering via `HAVING`, and string manipulations, while working within the constraints of the provided schema. It focuses on selecting top-ranked posts based on specified criteria and their associated metadata, encapsulating a typical performance benchmarking query structure.
