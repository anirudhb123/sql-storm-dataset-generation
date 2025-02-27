WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
), PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = pt.Tags::jsonb->>'id'::int
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5
), RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    pt.TagPostCount,
    rc.CommentCount
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Title ILIKE '%' || pt.TagName || '%'
LEFT JOIN 
    RecentComments rc ON rp.Id = rc.PostId
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
