WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.ViewCount > 1000 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
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
)
SELECT 
    up.OwnerDisplayName,
    up.Title,
    up.CreationDate,
    up.UpVotes,
    up.DownVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    up.ViewCount,
    CASE 
        WHEN COALESCE(up.UpVotes, 0) > COALESCE(up.DownVotes, 0) 
        THEN 'Positive'
        WHEN COALESCE(up.UpVotes, 0) < COALESCE(up.DownVotes, 0)
        THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    (SELECT * FROM RankedPosts WHERE rn = 1) AS up
LEFT JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
ORDER BY 
    up.ViewCount DESC
LIMIT 10;
