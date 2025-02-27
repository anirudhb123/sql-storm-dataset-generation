
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1   
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR  
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  
),
PostsWithComments AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.Tags,
        fp.CreationDate,
        fp.OwnerDisplayName,
        fp.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.OwnerDisplayName, fp.Score
),
TopPosts AS (
    SELECT 
        pwc.*,
        RANK() OVER (ORDER BY pwc.Score DESC) AS PopularityRank
    FROM 
        PostsWithComments pwc
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS RelatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts post ON tp.PostId = post.Id
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(post.Tags, '><', numbers.n), '><', -1)) AS tag_name
     FROM (SELECT @row := @row + 1 AS n FROM 
           (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
           (SELECT @row := 0) r) numbers
     WHERE @row < CHAR_LENGTH(post.Tags) - CHAR_LENGTH(REPLACE(post.Tags, '><', '')) + 1) AS tag_name ON tag_name IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    tp.PopularityRank <= 10  
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.OwnerDisplayName, tp.Score, tp.CommentCount
ORDER BY 
    tp.Score DESC;
