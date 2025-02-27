WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pv.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        EXTRACT(EPOCH FROM NOW() - p.CreationDate) AS AgeInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        (p.Body ILIKE '%performance%' OR p.Title ILIKE '%performance%')
),
PostTagCounts AS (
    SELECT 
        Unnest(string_to_array(Tags, ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        PostTagCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AgeInSeconds,
    tt.Tag AS TopTag
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TagRank <= 5
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

This SQL query benchmarks string processing capabilities by extracting relevant posts discussing "performance" from the past year, ranking them by score and view count, while also identifying the top 5 tags associated with these posts. The query utilizes common table expressions (CTEs) to aggregate and rank data effectively, ensuring efficient processing for performance evaluation.
