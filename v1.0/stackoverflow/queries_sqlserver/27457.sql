
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
        p.PostTypeId = 1 
),

TagStats AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
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
    TopTags t ON r.Tags LIKE '%' + t.TagName + '%'
WHERE 
    r.PostRank = 1 
AND 
    t.TagRank <= 5 
ORDER BY 
    r.CreationDate DESC;
