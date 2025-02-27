
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
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
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
    PostTagCounts pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(ft.Tags, 2, LEN(ft.Tags) - 2), '><'))
ORDER BY 
    pt.PostCount DESC, 
    ft.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
