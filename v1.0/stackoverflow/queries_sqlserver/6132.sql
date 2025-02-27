
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
        AND p.PostTypeId = 1
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, ',')
    WHERE 
        CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    pt.TagName,
    pt.TagCount,
    rp.PostRank
FROM 
    RankedPosts rp
JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
JOIN 
    Tags t ON pl.RelatedPostId = t.WikiPostId
JOIN 
    PopularTags pt ON t.TagName = pt.TagName
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank, pt.TagCount DESC;
