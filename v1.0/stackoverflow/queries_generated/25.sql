WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
    up.DisplayName,
    COUNT(DISTINCT rp.Id) AS TopPostCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
    COALESCE(SUM(p.UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(p.DownVotes), 0) AS TotalDownVotes,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    Posts p ON p.OwnerUserId = up.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    up.Reputation > 1000
GROUP BY 
    up.Id, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    TotalUpVotes DESC, TotalViews DESC
LIMIT 10;

-- Additional complexity by joining with Votes
WITH PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.Id) AS TopPostCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(SUM(pvs.UpVotes), 0) AS TotalUpVotes,
    COALESCE(SUM(pvs.DownVotes), 0) AS TotalDownVotes
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.PostRank <= 5
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    up.Reputation > 1000 
    AND NOT EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = up.Id AND b.TagBased = 1)
GROUP BY 
    up.Id, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    TotalUpVotes DESC
LIMIT 10;
