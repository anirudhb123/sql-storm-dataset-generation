WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, -1) as HasAcceptedAnswer,  -- to differentiate questions without accepted answers
        p.Tags,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN p.PostTypeId = 1 THEN 'Question' 
                ELSE 'Other'
            END 
            ORDER BY 
                p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'  -- posts created in the last year
        AND p.Score > 0  -- ensuring relevance
),
UniqueTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        Tags IS NOT NULL
),
TagFrequency AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        UniqueTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10  -- filtering for tags used in more than 10 posts
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.HasAcceptedAnswer,
        rp.ViewCount,
        rp.Score,
        ARRAY_AGG(DISTINCT tf.Tag) AS PopularTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagFrequency tf ON tf.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.HasAcceptedAnswer, rp.ViewCount, rp.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    CASE WHEN ps.HasAcceptedAnswer = -1 THEN 'No Accepted Answer' ELSE 'Has Accepted Answer' END AS AcceptedAnswer,
    ps.ViewCount,
    ps.Score,
    ARRAY_LENGTH(ps.PopularTags, 1) AS TagCount,
    ps.PopularTags
FROM 
    PostStatistics ps
WHERE 
    ps.TagCount > 0  -- Only showing posts with popular tags
ORDER BY 
    ps.ViewCount DESC,  -- Order by ViewCount descending
    ps.Score DESC;  -- Then by Score descending
