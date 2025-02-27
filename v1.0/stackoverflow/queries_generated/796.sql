WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount
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
FilteredUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    COALESCE(p.CommentCount, 0) AS Comments,
    p.UpVotes,
    p.DownVotes,
    CASE 
        WHEN p.UserRank = 1 THEN 'Top Post'
        WHEN p.Score > 50 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts p
JOIN 
    FilteredUsers u ON p.OwnerUserId = u.Id
WHERE 
    (p.ViewCount > 100 OR p.UpVotes > p.DownVotes)
    AND p.UserRank <= 3
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 50;
