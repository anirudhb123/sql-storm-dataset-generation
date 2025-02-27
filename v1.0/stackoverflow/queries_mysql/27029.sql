
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        rn <= 5 
),
TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
FrequentTags AS (
    SELECT 
        TagName
    FROM 
        TagStats
    WHERE 
        PostCount > 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    ft.TagName
FROM 
    RecentPosts rp
JOIN 
    FrequentTags ft ON FIND_IN_SET(ft.TagName, TRIM(BOTH '<>' FROM REPLACE(rp.Tags, '><', ',')))
ORDER BY 
    rp.CreationDate DESC;
