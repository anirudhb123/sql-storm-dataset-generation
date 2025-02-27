WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
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
        rp.ViewCount,
        rp.AnswerCount,
        us.DisplayName,
        us.Reputation,
        us.Views,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.OwnerUserId = us.Id
    WHERE 
        rp.Rank <= 5
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    us.DisplayName AS Owner,
    us.Reputation,
    us.Views,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    CASE 
        WHEN p.Score > 0 THEN 'Positive'
        WHEN p.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Score_Status,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.PostId) AS CommentCount,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.ExcerptPostId = p.PostId) AS Tags
FROM 
    TopPosts p
LEFT JOIN 
    Votes v ON p.PostId = v.PostId AND v.VoteTypeId = 2
GROUP BY 
    p.PostId, p.Title, p.Score, p.ViewCount, p.AnswerCount, us.DisplayName, us.Reputation, us.Views, us.GoldBadges, us.SilverBadges, us.BronzeBadges
ORDER BY 
    p.Score DESC;
