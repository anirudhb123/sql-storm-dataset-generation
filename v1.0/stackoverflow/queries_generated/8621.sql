WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    pt.TagName,
    rt.Rank
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
JOIN 
    PopularTags p ON pt.TagName = p.TagName
JOIN 
    (SELECT 
         PostId, COUNT(PostId) AS Rank 
     FROM 
         PostLinks 
     GROUP BY 
         PostId) rt ON rp.PostId = rt.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
