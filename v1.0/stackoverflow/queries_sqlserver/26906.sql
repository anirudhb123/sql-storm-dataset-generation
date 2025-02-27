
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName,
        ts.TagName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY (SELECT value AS tag FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>')) AS tags 
    LEFT JOIN 
        Tags ts ON ts.TagName = tags.tag
    WHERE 
        pt.Name = 'Question' 
        AND p.CreationDate >= CAST('2022-01-01' AS DATE)
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
