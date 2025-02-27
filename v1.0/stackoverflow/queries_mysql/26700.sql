
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.Score > 0   
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    JOIN 
        RankedPosts ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.Tags IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Author,
    rp.CreationDate,
    tc.Tag AS TopTag,
    pwc.CommentCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tc ON rp.Tags LIKE CONCAT('%', tc.Tag, '%')
JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Author, rp.CreationDate DESC;
