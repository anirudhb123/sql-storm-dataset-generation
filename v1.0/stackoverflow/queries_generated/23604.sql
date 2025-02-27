WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ur.Reputation,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        p.Body
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalReport AS (
    SELECT 
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.Reputation,
        tp.GoldBadges,
        tp.SilverBadges,
        tp.BronzeBadges,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN tp.Score > 50 THEN 'High Scorer'
            WHEN tp.Score BETWEEN 20 AND 50 THEN 'Medium Scorer'
            WHEN tp.Score < 20 THEN 'Low Scorer'
            ELSE 'No Score'
        END AS ScoreCategory,
        CASE 
            WHEN tp.ViewCount IS NULL THEN 'No Views'
            WHEN tp.ViewCount > 1000 THEN 'Popular Post'
            ELSE 'Less Popular Post'
        END AS Popularity
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
    ORDER BY 
        tp.Score DESC, tp.ViewCount DESC
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    (GoldBadges > 0 OR SilverBadges > 0)
    AND Reputation > 100
    AND (ScoreCategory = 'High Scorer' OR Popularity = 'Popular Post')

