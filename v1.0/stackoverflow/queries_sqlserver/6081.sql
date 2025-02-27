
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),

PopularHashtags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    ph.TagName
FROM 
    RankedPosts rp
JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
JOIN 
    PopularHashtags ph ON pl.RelatedPostId = (SELECT TOP 1 Id FROM Posts WHERE Tags LIKE '%' + ph.TagName + '%' )
WHERE 
    rp.PostRank <= 50
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
