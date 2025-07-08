
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2024-10-01 12:34:56'::TIMESTAMP - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        TRIM(SPLIT_PART(Tags, '>', seq)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => (SELECT MAX(LENGTH(Tags) - LENGTH(REPLACE(Tags, '>', '')) + 1) FROM Posts WHERE PostTypeId = 1 AND CreationDate >= '2024-10-01 12:34:56'::TIMESTAMP - INTERVAL '1 year'))) AS seq
    WHERE 
        PostTypeId = 1
        AND CreationDate >= '2024-10-01 12:34:56'::TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    pt.TagName,
    rp.TagRank
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON POSITION(pt.TagName IN rp.Tags) > 0
WHERE 
    rp.TagRank <= 5
ORDER BY 
    rp.ViewCount DESC, 
    rp.OwnerReputation DESC;
