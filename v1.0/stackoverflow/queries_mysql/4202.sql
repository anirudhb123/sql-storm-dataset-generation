
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @prev_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.PostID,
    p.Title,
    p.Score,
    p.CreationDate,
    COALESCE(u.DisplayName, 'Anonymous') AS Owner,
    p.UpvoteCount,
    p.CommentCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    RankedPosts p
LEFT JOIN 
    UserStats u ON p.OwnerUserId = u.UserID
WHERE 
    p.Rank = 1 OR p.PostID IS NULL
ORDER BY 
    p.Score DESC;
