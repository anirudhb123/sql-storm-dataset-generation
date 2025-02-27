
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01 12:34:56') AS datetime2)
), 
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Tags,
        OwnerDisplayName,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
), 
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS t
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
), 
MostUsedTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        PostCount > 100
)
SELECT 
    trp.OwnerDisplayName,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    mut.TagName AS MostUsedTag,
    mut.PostCount AS MostUsedTagPostCount
FROM 
    TopRankedPosts trp
JOIN 
    MostUsedTags mut ON trp.Tags LIKE '%' + mut.TagName + '%'
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
