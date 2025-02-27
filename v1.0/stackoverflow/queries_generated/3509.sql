WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rb.GoldBadges,
        rb.SilverBadges,
        rb.BronzeBadges,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = rb.UserId)
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    pd.ScoreCategory,
    COALESCE(ut.DisplayName, 'Anonymous') AS UserDisplayName
FROM 
    PostDetails pd
LEFT JOIN 
    Users ut ON pd.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ut.Id)
WHERE 
    pd.ScoreRank <= 5
ORDER BY 
    pd.Score DESC
LIMIT 50;
