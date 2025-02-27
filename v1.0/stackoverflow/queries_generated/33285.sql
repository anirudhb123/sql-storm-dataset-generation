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
        p.CreationDate >= NOW() - INTERVAL '1 year' 
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
        COALESCE(cm.CommentCount, 0) as TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagArray(Tag) ON TRUE
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
LIMIT 10;

This query uses various SQL constructs such as Common Table Expressions (CTEs), window functions, outer joins, and conditions to produce a result set that ranks the most recent posts from various post types, while filtering for those with significant comment activity and applies further constraints based on user-defined parameters.
