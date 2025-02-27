WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
FilteredComments AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments 
    GROUP BY 
        PostId
),
OuterJoinResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(fc.TotalComments, 0) AS TotalComments,
        COALESCE(fc.AverageCommentScore, 0) AS AverageCommentScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FilteredComments fc ON rp.PostId = fc.PostId
)
SELECT 
    ojr.PostId,
    ojr.Title,
    ojr.CreationDate,
    ojr.Score,
    ojr.ViewCount,
    ojr.OwnerDisplayName,
    ojr.TotalComments,
    ojr.AverageCommentScore
FROM 
    OuterJoinResults ojr
WHERE 
    ojr.TotalComments > 5 
    OR (ojr.AverageCommentScore > 1 AND ojr.Score > 100)
ORDER BY 
    ojr.Score DESC, ojr.ViewCount DESC
LIMIT 10;

-- Check for slogan-like posts with specific string patterns in the title
WITH SloganPosts AS (
    SELECT 
        DISTINCT p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount
    FROM 
        Posts p
    WHERE 
        p.Title ILIKE '%how to%' 
        OR p.Title ILIKE '%what is%' 
        OR p.Title ILIKE '%best way%'
)
SELECT 
    sp.Id, 
    sp.Title, 
    COALESCE(rp.Score, 0) AS RankScore
FROM 
    SloganPosts sp
LEFT JOIN 
    RankedPosts rp ON sp.Id = rp.PostId
WHERE 
    rp.RowNum IS NOT NULL
ORDER BY 
    RankScore DESC;
