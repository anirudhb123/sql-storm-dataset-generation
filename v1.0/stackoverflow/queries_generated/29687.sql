WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Body IS NOT NULL
),
TagCounts AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagFrequency
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        Tag
),
MostFrequentTags AS (
    SELECT 
        Tag,
        ROW_NUMBER() OVER (ORDER BY TagFrequency DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagFrequency > 5 -- Tags used more than 5 times
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    mft.Tag AS FrequentTag,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteValue) AS TotalVotes,
    u.DisplayName AS OwnerDisplayName
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
LEFT JOIN 
    Votes v ON v.PostId = rp.PostId
CROSS JOIN 
    Users u ON u.Id = rp.OwnerUserId
JOIN 
    MostFrequentTags mft ON mft.Tag = ANY(string_to_array(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><'))
WHERE 
    rp.PostRank = 1 -- Get the most recent post for each tag
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, mft.Tag, u.DisplayName
ORDER BY 
    COUNT(c.Id) DESC, SUM(v.VoteValue) DESC;

