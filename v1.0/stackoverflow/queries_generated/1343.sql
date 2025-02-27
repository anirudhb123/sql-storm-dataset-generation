WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8  -- BountyStart votes
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), LatestVotes AS (
    SELECT 
        PostId,
        UserId,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS VoteRank
    FROM 
        Votes
    WHERE 
        VoteTypeId IN (2, 3)  -- UpVotes, DownVotes
), UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount, 
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UserRank,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN lv.VoteRank = 1 THEN 'Recently Voted' 
        ELSE 'Older Vote' 
    END AS VoteStatus,
    rp.TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    LatestVotes lv ON rp.PostId = lv.PostId
WHERE 
    rp.ViewCount > 10
    AND (rp.Score >= 5 OR rp.TotalBounty > 0)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
