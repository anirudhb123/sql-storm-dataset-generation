WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
CommentsWithTags AS (
    SELECT 
        c.Id AS CommentId,
        c.Text AS CommentText,
        c.CreationDate,
        c.UserDisplayName,
        p.Title AS PostTitle,
        t.TagName
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    CROSS JOIN 
        PopularTags t
    WHERE 
        p.PostTypeId = 1
        AND c.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days')
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ct.CommentId,
    ct.CommentText,
    ct.CreationDate AS CommentCreationDate,
    ct.UserDisplayName AS CommentUser,
    ct.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentsWithTags ct ON rp.PostId = ct.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
