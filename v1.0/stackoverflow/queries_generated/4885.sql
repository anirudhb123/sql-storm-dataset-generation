WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
),
MostUpvotedPost AS (
    SELECT 
        PostId,
        Title,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN UserId IS NOT NULL THEN 1 END) AS NonAnonymousComments,
        COUNT(CASE WHEN UserId IS NULL THEN 1 END) AS AnonymousComments
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    mp.Title,
    mp.Score,
    COALESCE(cc.NonAnonymousComments, 0) AS NonAnonymousCount,
    COALESCE(cc.AnonymousComments, 0) AS AnonymousCount,
    CASE 
        WHEN cc.NonAnonymousComments IS NULL THEN 'No Comments'
        ELSE 'Comments Exist'
    END AS CommentStatus,
    CASE 
        WHEN mp.Score > 100 THEN 'High Scorer'
        ELSE 'Regular'
    END AS PostCategory,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.WikiPostId = (SELECT p.WikiPostId FROM Posts p WHERE p.Id = mp.PostId)) AS RelatedTags
FROM 
    MostUpvotedPost mp
LEFT JOIN 
    CommentCounts cc ON mp.PostId = cc.PostId
WHERE 
    mp.Score > 0
ORDER BY 
    mp.Score DESC;
