WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        (us.GoldBadges + us.SilverBadges + us.BronzeBadges) AS TotalBadges,
        COALESCE(SUM(rp.Score), 0) AS TotalScore
    FROM 
        UserStats us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation, us.PostCount
    HAVING 
        us.PostCount > 5 -- Only users with more than 5 posts
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE()) -- Activity in the last 6 months
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalBadges,
    tu.TotalScore,
    ra.CommentCount,
    ra.CloseCount
FROM 
    TopUsers tu
LEFT JOIN 
    RecentActivity ra ON tu.UserId = ra.OwnerUserId
WHERE 
    (ra.CommentCount IS NOT NULL OR ra.CloseCount > 0) -- Users with recent activity
ORDER BY 
    tu.TotalScore DESC, tu.Reputation DESC
OPTION (MAXRECURSION 0); -- Allow recursion if needed for any further CTEs
