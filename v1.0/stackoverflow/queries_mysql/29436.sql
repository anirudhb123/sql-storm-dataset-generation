
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    CROSS JOIN 
        (SELECT @row_number := 0) AS r
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostID,
        Title,
        CreationDate,
        Body,
        Tags,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),
TaggedPosts AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.VoteCount,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        TopPosts tp
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, ',', '')) >= numbers.n - 1
)
SELECT 
    tp.PostID,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    COUNT(DISTINCT tp.TagName) AS UniqueTagCount
FROM 
    TaggedPosts tp
GROUP BY 
    tp.PostID, tp.Title, tp.OwnerDisplayName, tp.CommentCount, tp.VoteCount
ORDER BY 
    UniqueTagCount DESC, VoteCount DESC
LIMIT 5;
