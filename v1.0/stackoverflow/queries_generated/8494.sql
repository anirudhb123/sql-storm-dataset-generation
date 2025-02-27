WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        AVG(v.VoteTypeId = 2) AS UpvoteRatio
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers only
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        RankPerUser,
        UpvoteRatio
    FROM 
        RankedPosts
    WHERE 
        RankPerUser <= 5 -- Top 5 posts per user
)
SELECT 
    trp.*, 
    CASE 
        WHEN UpvoteRatio > 0.5 THEN 'Highly Upvoted'
        WHEN UpvoteRatio BETWEEN 0.3 AND 0.5 THEN 'Moderately Upvoted'
        ELSE 'Less Upvoted'
    END AS UpvoteCategory
FROM 
    TopRankedPosts trp
ORDER BY 
    Score DESC, CreationDate DESC;
