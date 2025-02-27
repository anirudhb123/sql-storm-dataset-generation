
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        PostID,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        Score,
        OwnerDisplayName,
        LastEditComment,
        LastEditDate
    FROM 
        PostAnalytics
    WHERE 
        EditRank = 1  
        AND Score > 10  
        AND ViewCount > 100  
),
TagCount AS (
    SELECT 
        TRIM(tag) AS Tag,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS tag
        FROM 
            FilteredPosts
        INNER JOIN 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
            ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    ) AS TagsTable
    GROUP BY 
        TRIM(tag
    )
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagCount, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.Score,
    fp.OwnerDisplayName,
    tt.Tag,
    tt.PostCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.Tag IN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, ',', numbers.n), ',', -1)) 
                              FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
                                    UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 
                                    UNION SELECT 9 UNION SELECT 10) numbers 
                              WHERE CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, ',', '')) >= numbers.n - 1)
                             )
WHERE 
    tt.Rank <= 5  
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate DESC;
