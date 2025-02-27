WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(vB.BountyAmount) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes vB ON u.Id = vB.UserId AND vB.VoteTypeId = 8  -- Bounty votes only
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted history
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    ph.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.CommentCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.AverageBounty,
    CASE 
        WHEN hp.PostId IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus,
    MAX(rp.Score) AS MaxScore
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryCTE hp ON rp.PostId = hp.PostId AND hp.HistoryRank = 1
WHERE 
    (up.Reputation > 100 OR up.GoldBadges > 0)  -- Filtering criteria for users
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, ph.PostId, rp.Title, 
    rp.CreationDate, rp.CommentCount, up.GoldBadges, up.SilverBadges, 
    up.BronzeBadges, up.AverageBounty, hp.PostId
ORDER BY 
    MaxScore DESC, up.Reputation DESC;
