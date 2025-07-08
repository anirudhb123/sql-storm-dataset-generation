
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
PostTagCounts AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')) AS value
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(value)
)
SELECT 
    ft.Title,
    ft.OwnerDisplayName,
    ft.Score,
    pt.TagName,
    pt.PostCount,
    ft.CreationDate
FROM 
    FilteredPosts ft
JOIN 
    PostTagCounts pt ON pt.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(SUBSTRING(ft.Tags, 2, LEN(ft.Tags) - 2), '><')) AS value)
ORDER BY 
    pt.PostCount DESC, 
    ft.Score DESC
LIMIT 10;
