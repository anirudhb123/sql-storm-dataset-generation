WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2::smallint) OVER (PARTITION BY p.Id) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        (p.ClosedDate IS NULL OR p.ClosedDate > NOW())
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(ub.GoldCount, 0) AS GoldBadges,
    COALESCE(ub.SilverCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeCount, 0) AS BronzeBadges,
    p.CommentCount,
    p.UpVotes
FROM 
    Users u
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId AND p.rn = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.DisplayName ASC, p.Score DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
