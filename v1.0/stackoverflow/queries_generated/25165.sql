WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ',') ORDER BY p.Score DESC) AS RankByTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.RankByTags
FROM 
    RankedPosts rp
WHERE 
    rp.RankByTags <= 5 -- Limit to top 5 ranked questions per tag
ORDER BY 
    rp.RankByTags, 
    rp.Score DESC;

This query benchmarks string processing by performing various operations, including string aggregation and manipulation, while enumerating top-ranked questions based on their tags and scores. It retrieves questions that are grouped by their associated tags, ranks them according to their scores, and limits the result set to the highest ranked questions per each tag.
