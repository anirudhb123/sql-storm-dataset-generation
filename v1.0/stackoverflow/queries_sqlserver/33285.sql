
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) 
        AND p.Score > 0
),
MostCommentedPosts AS (
    SELECT 
        PostId, 
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
        COALESCE(cm.CommentCount, 0) AS TotalComments
    FROM 
        Posts p
    OUTER APPLY 
        (SELECT Tag AS Tag 
         FROM STRING_SPLIT(p.Tags, ',')) AS TagArray
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(TagArray.Tag)
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
