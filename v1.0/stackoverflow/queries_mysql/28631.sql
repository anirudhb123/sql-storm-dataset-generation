
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Tags, u.DisplayName
),

TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', numbers.n), '> <', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN 
    (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '> <', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  
),

TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.ViewCount,
        pd.CommentCount,
        pd.VoteCount,
        @row_number := IF(@prev_view = pd.ViewCount, @row_number, @row_number + 1) AS Rank,
        @prev_view := pd.ViewCount
    FROM 
        PostDetails pd
    CROSS JOIN (SELECT @row_number := 0, @prev_view := NULL) r
    JOIN 
        TagStatistics ts ON pd.Tags LIKE CONCAT('%', ts.TagName, '%')
    ORDER BY 
        pd.ViewCount DESC
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.ViewCount DESC;
