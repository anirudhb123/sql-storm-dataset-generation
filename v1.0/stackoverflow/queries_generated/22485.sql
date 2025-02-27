WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(DISTINCT pl.RelatedPostId) FROM PostLinks pl WHERE pl.PostId = p.Id) AS RelatedLinksCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year') AND
        p.PostTypeId = 1
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)

SELECT 
    up.UserId,
    COALESCE(SUM(rp.ViewCount), 0) AS TotalViewCount,
    COALESCE(MAX(rp.CommentCount), 0) AS MaxCommentCount,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN COUNT(rp.PostId) > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS UserStatus
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
GROUP BY 
    up.UserId
HAVING 
    COALESCE(SUM(rp.ViewCount), 0) > 1000 -- Only those with over 1000 total views

UNION ALL

SELECT 
    -1 AS UserId, 
    0 AS TotalViewCount, 
    0 AS MaxCommentCount, 
    0 AS TotalBadges, 
    0 AS GoldBadges, 
    0 AS SilverBadges, 
    0 AS BronzeBadges,
    'Not Applicable' AS UserStatus
WHERE 
    NOT EXISTS (SELECT 1 FROM Users);

WITH RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    WHERE 
        CreationDate >= (NOW() - INTERVAL '30 days')
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewRank,
    rv.Upvotes,
    rv.Downvotes,
    (CASE 
        WHEN rv.Upvotes - rv.Downvotes > 0 THEN 'Positive'
        WHEN rv.Upvotes - rv.Downvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END) AS VoteSentiment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.ViewRank = 1
ORDER BY 
    rp.ViewRank;


