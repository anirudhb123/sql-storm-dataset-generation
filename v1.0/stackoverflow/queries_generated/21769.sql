WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
HighScoredPosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rb.UserId,
        rb.BadgeCount,
        rb.GoldCount,
        rb.SilverCount,
        rb.BronzeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    WHERE 
        rp.Score > 100 AND 
        rb.BadgeCount IS NOT NULL
),
CommentedPosts AS (
    SELECT 
        PostId,
        AVG(Score) AS AverageScore
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.BadgeCount,
    COALESCE(cp.AverageScore, 0) AS AverageCommentScore,
    (CASE 
         WHEN hsp.GoldCount > 0 THEN 'Gold'
         WHEN hsp.SilverCount > 0 THEN 'Silver'
         WHEN hsp.BronzeCount > 0 THEN 'Bronze'
         ELSE 'No Badge'
     END) AS HighestBadge
FROM 
    HighScoredPosts hsp
LEFT JOIN 
    CommentedPosts cp ON hsp.PostId = cp.PostId
ORDER BY 
    hsp.Score DESC,
    hsp.BadgeCount DESC
LIMIT 10;


This query performs the following operations:

1. **RankedPosts CTE**: Ranks posts created within the last year by score for each user and counts the comments for each post.
   
2. **UserBadges CTE**: Computes the number of badges held by users with a reputation greater than 100, segmented by badge class.

3. **HighScoredPosts CTE**: Joins the ranked posts with user badge counts and filters for posts with a score greater than 100.

4. **CommentedPosts CTE**: Calculates the average score of comments for each post.

5. **Final SELECT**: Combines data from `HighScoredPosts` and `CommentedPosts`, assessing the highest badge type for each post and including average comment scores. The results are ordered and limited to the top 10. 

This query utilizes various SQL constructs, including CTEs, aggregations, window functions, and conditional expressions to create a comprehensive analysis of high-scoring posts by users with sufficient reputation and their badge statuses.
