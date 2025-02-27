
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag ON tag.value IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        TagsArray
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
)
SELECT 
    tp.OwnerDisplayName,
    COUNT(DISTINCT tp.PostId) AS PostCount,
    SUM(tp.ViewCount) AS TotalViews,
    SUM(tp.Score) AS TotalScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags
FROM 
    TopPosts tp
LEFT JOIN 
    STRING_SPLIT(tp.TagsArray, ', ') AS t ON 1=1
GROUP BY 
    tp.OwnerDisplayName
ORDER BY 
    TotalScore DESC, TotalViews DESC;
