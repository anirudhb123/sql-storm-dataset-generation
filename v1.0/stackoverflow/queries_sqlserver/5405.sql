
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.LastActivityDate DESC) AS RankByOwner
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByOwner = 1
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS t
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC 
)
SELECT TOP 5
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    pt.TagName,
    pt.PostCount
FROM 
    TopPosts tp
CROSS JOIN 
    PopularTags pt
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
