WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags, 
        u.DisplayName AS Author, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),

TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName, 
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStats
)

SELECT 
    r.Author,
    r.Title,
    r.Body,
    r.CreationDate,
    t.TagName,
    t.TagCount
FROM 
    RankedPosts r
JOIN 
    TopTags t ON r.Tags LIKE '%' || t.TagName || '%'
WHERE 
    r.PostRank = 1 -- Only the most recent question per user
AND 
    t.TagRank <= 5 -- Top 5 tags
ORDER BY 
    r.CreationDate DESC;
