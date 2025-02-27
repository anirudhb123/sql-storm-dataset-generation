
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
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
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
        value AS TagName
    FROM 
        STRING_SPLIT((SELECT STRING_AGG(Tags, '') FROM Posts WHERE PostTypeId = 1), '><')
    GROUP BY 
        value
    ORDER BY 
        COUNT(*) DESC
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
    PopularTags t ON tp.Title LIKE '%' + t.TagName + '%' 
ORDER BY 
    t.TagName, tp.Score DESC;
