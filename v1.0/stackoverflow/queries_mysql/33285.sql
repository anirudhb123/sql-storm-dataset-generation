
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.Score > 0
),
MostCommentedPosts AS (
    SELECT 
        C.PostId, 
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        t.TagName,
        COALESCE(cm.CommentCount, 0) as TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS Tag
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
           UNION ALL SELECT 9 UNION ALL SELECT 10) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS TagArray ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TagArray.Tag
    LEFT JOIN 
        MostCommentedPosts cm ON p.Id = cm.PostId
)
SELECT 
    wp.PostId,
    wp.Title,
    wp.TagName,
    wp.TotalComments,
    rp.OwnerName
FROM 
    PostsWithTags wp
JOIN 
    RankedPosts rp ON wp.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
    AND wp.TotalComments > 5
ORDER BY 
    wp.TotalComments DESC, 
    rp.CreationDate DESC
LIMIT 10;
