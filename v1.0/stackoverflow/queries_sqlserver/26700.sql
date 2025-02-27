
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
        value AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, ',') 
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    TopTags tc ON rp.Tags LIKE '%' + tc.Tag + '%'
JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Author, rp.CreationDate DESC;
