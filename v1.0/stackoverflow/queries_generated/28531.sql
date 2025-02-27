WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
)
, PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 -- Tags used in more than 5 questions
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.PostRank = 1 -- Select latest question per user
ORDER BY 
    rp.CreationDate DESC, 
    pt.TagCount DESC
LIMIT 10; -- Show top 10 latest questions with popular tags
