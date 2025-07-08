
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
        TRIM(REGEXP_SUBSTR(tag, '[^><]+', 1, seq)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) seq
    CROSS JOIN 
        (SELECT DISTINCT Tags FROM Posts WHERE PostTypeId = 1) AS tags
    WHERE 
        PostTypeId = 1 
        AND seq <= REGEXP_COUNT(Tags, '><') + 1
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
    TopTags t ON POSITION(t.TagName IN r.Tags) > 0
WHERE 
    r.PostRank = 1 
AND 
    t.TagRank <= 5 
ORDER BY 
    r.CreationDate DESC;
