WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
FilteredTags AS (
    SELECT 
        PostId,
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        FilteredTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 -- Only keep tags that are used in more than 5 questions
),
MostFrequentTags AS (
    SELECT 
        DISTINCT Tag
    FROM 
        TagCounts
    ORDER BY 
        TagFrequency DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Author,
    rp.Reputation,
    STRING_AGG(mft.Tag, ', ') AS FrequentTags
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredTags ft ON rp.PostId = ft.PostId
JOIN 
    MostFrequentTags mft ON ft.Tag = mft.Tag
WHERE 
    rp.PostRank <= 3 -- Change rank limit as necessary
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.Author, rp.Reputation
ORDER BY 
    rp.CreationDate DESC;
