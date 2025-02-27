WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostCommentCount AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(pcc.CommentCount, 0) AS TotalComments,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rp.Score > 100 THEN 'High Scorer'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostCommentCount pcc ON rp.Id = pcc.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC
LIMIT 50;
