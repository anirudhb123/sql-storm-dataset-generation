WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 AND p.PostTypeId = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) as CommentCount,
        MAX(c.CreationDate) as LatestCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(pc.CommentCount, 0) as CommentCount,
        pc.LatestCommentDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    WHERE 
        rp.UserPostRank <= 3 -- Top 3 posts per user
)

SELECT 
    hsp.Id,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.CommentCount,
    CASE 
        WHEN hsp.LatestCommentDate IS NULL THEN 'No comments'
        ELSE 'Has comments'
    END AS CommentStatus
FROM 
    HighScoringPosts hsp
WHERE 
    hsp.Score > 10
ORDER BY 
    hsp.Score DESC, hsp.CreationDate DESC

UNION ALL

SELECT 
    NULL, 
    'Total High Scoring Posts', 
    NULL, 
    COUNT(*), 
    NULL, 
    NULL 
FROM 
    HighScoringPosts;
