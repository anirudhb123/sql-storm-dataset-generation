
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
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tags ON TRUE
    LEFT JOIN 
        Tags ts ON ts.TagName = tags.tag
    WHERE 
        pt.Name = 'Question' 
        AND p.CreationDate >= '2022-01-01'
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
