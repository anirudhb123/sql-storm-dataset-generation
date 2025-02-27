WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseActions
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.BadgeCount,
    tu.TotalViews,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.PostCount,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    COALESCE(cp.CloseActions, 0) AS TotalCloseActions
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.OwnerRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    tu.TotalUpVotes > (SELECT AVG(TotalUpVotes) FROM TopUsers)
ORDER BY 
    tu.PostCount DESC, tu.TotalViews DESC;
