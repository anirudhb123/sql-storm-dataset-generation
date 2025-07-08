
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsList,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            TRIM(value) AS TagName, 
            p.Id AS PostId 
         FROM 
            Posts p, 
            TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))) AS f)) AS tag ON p.Id = tag.PostId
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName
    FROM 
        Posts,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><'))) AS f)
    WHERE 
        PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.CommentCount,
        rp.TagsList,
        rp.RankByViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.TagsList,
    pt.TagName AS PopularTag
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         TagName, 
         COUNT(*) AS UsageCount 
     FROM 
         PopularTags 
     GROUP BY 
         TagName 
     HAVING 
         COUNT(*) >= 5) pt ON tp.TagsList LIKE '%' || pt.TagName || '%'
ORDER BY 
    tp.ViewCount DESC, tp.CommentCount DESC;
