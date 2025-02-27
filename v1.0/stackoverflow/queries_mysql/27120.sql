
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ph.UserDisplayName AS LastEditor,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 7 DAY
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, ph.UserDisplayName
),
TagCounts AS (
    SELECT 
        PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount
    FROM 
        FilteredPosts fp
    JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '>', '')) >= numbers.n - 1) AS t
    GROUP BY 
        PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.LastEditor,
    fp.LastEditDate,
    fp.CommentCount,
    fc.UniqueTagCount,
    fp.AnswerCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagCounts fc ON fp.PostId = fc.PostId
ORDER BY 
    fp.CreationDate DESC;
