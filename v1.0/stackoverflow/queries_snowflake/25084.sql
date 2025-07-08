
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AcceptedAnswerId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY tag UNNEST(string_split(substring(p.Tags, 2, length(p.Tags)-2), '><')) ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        tag AS TagName, 
        COUNT(*) AS Frequency
    FROM 
        Posts,
        LATERAL FLATTEN(input => string_split(substring(Tags, 2, length(Tags) - 2), '><')) AS tag
    WHERE 
        PostTypeId = 1
    GROUP BY 
        tag
    ORDER BY 
        Frequency DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    pt.Frequency
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName = rp.Tags
WHERE 
    rp.TagRank <= 5
ORDER BY 
    pt.Frequency DESC, 
    rp.CreationDate DESC;
