
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
FilteredTags AS (
    SELECT 
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(TRIM(BOTH '<>' FROM Tags), '><')
    GROUP BY 
        value
    HAVING 
        COUNT(*) > 10 
),
TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    JOIN 
        FilteredTags ft ON rp.Tags LIKE '%' + ft.Tag + '%'
    WHERE 
        rp.TagRank <= 5 
)
SELECT TOP 50
    tp.OwnerDisplayName,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;
