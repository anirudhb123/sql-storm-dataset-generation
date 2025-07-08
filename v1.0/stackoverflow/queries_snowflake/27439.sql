
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp) 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Author
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(Tags, '><')) 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        COUNT(*) DESC
    LIMIT 10 
)
SELECT 
    t.TagName,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Author
FROM 
    TopPosts tp
JOIN 
    PopularTags t ON tp.Title ILIKE '%' || t.TagName || '%' 
ORDER BY 
    t.TagName, tp.Score DESC;
