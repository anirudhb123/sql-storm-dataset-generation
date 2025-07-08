
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName,
        TRIM(value) AS TagName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        TABLE(parse_json(replace(replace(p.Tags, '><', '","'), '<', '['), '>','}]'))::ARRAY) AS tags
    WHERE 
        pt.Name = 'Question' 
        AND p.CreationDate >= DATE '2022-01-01'
),
TopTagCounts AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount
    FROM 
        TaggedPosts
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC 
    LIMIT 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.OwnerDisplayName,
        tt.PostCount,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        TaggedPosts tp
    JOIN 
        TopTagCounts tt ON tp.TagName = tt.TagName 
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId 
    LEFT JOIN 
        PostHistory ph ON tp.PostId = ph.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.OwnerDisplayName, tt.PostCount
)
SELECT 
    pd.Title,
    pd.Body,
    pd.OwnerDisplayName,
    pd.PostCount,
    pd.CommentCount,
    pd.LastEditDate
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.PostCount DESC, pd.LastEditDate DESC;
