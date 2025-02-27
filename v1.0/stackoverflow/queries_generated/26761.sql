WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.Tags) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Score > 0   -- Only positively scored questions
),
TopTagQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        u.DisplayName AS OwnerDisplayName,
        rp.Score,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Rank,
        rp.TagCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank = 1  -- Top question per tag
)
SELECT 
    ttq.Title,
    ttq.Body,
    ttq.OwnerDisplayName,
    ttq.Score,
    ttq.CreationDate,
    ttq.LastActivityDate,
    STRING_AGG(t.TagName, ', ') AS RelatedTags
FROM 
    TopTagQuestions ttq
LEFT JOIN 
    STRING_SPLIT(ttq.Tags, '>') AS TagList ON TagList.value IS NOT NULL
JOIN 
    Tags t ON t.TagName = TRIM(TagList.value)
GROUP BY 
    ttq.PostId, ttq.Title, ttq.Body, ttq.OwnerDisplayName, 
    ttq.Score, ttq.CreationDate, ttq.LastActivityDate
ORDER BY 
    ttq.Score DESC, ttq.CreationDate DESC
FETCH FIRST 10 ROWS ONLY; 
