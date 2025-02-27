WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    tp.TagName,
    tp.TagCount
FROM 
    RankedPosts rp
JOIN 
    TagPopularity tp ON tp.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

This SQL query performs the following operations:

1. It creates a `RankedPosts` Common Table Expression (CTE) that ranks posts created in the last year by each user. Each post is assigned a rank based on its creation date.
  
2. It defines a `PopularTags` CTE that extracts tags from posts that are questions, ensuring we only consider tag data relevant for questions.

3. It aggregates these tags into a `TagPopularity` CTE that counts how many times each tag appears across the questions and selects the top 10 most popular tags.

4. Finally, it selects the most recent post from each user along with the most popular tags and their counts, ordered by score and view count.
