WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    up.DisplayName AS UserDisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    p.AnswerCount,
    p.CommentCount,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Pending'
    END AS AnswerStatus
FROM 
    RankedPosts p
JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    p.RankScore <= 5 
    AND (p.ViewCount > 100 OR p.AnswerCount > 3)
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 30;
