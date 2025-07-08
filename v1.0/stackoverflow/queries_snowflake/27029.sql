
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
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags)-2), '><')) AS value)
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
    FrequentTags ft ON ft.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(rp.Tags, 2, LENGTH(rp.Tags)-2), '><')) AS value))
ORDER BY 
    rp.CreationDate DESC;
