
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
        TRIM(BOTH '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
            (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) numbers,
            (SELECT @row := 0) r
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
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
    TopTags t ON r.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    r.PostRank = 1 
AND 
    t.TagRank <= 5 
ORDER BY 
    r.CreationDate DESC;
