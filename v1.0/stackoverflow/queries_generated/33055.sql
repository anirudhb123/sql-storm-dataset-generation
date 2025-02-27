WITH RecursivePostScore AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(v.BountyAmount), 0) + COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.OwnerUserId
), RecentPostChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -3, GETDATE())
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    rps.PostId,
    rps.TotalBounty,
    rps.VoteCount,
    rps.Rank,
    rpc.ChangeRank,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount >= 5 THEN 'Experienced'
        WHEN ub.BadgeCount BETWEEN 1 AND 4 THEN 'Newcomer'
        ELSE 'No Badges'
    END AS UserLevel,
    STRING_AGG(pt.Name, ', ') AS PostTypes
FROM 
    Users u
JOIN 
    RecursivePostScore rps ON u.Id = rps.PostId
LEFT JOIN 
    RecentPostChanges rpc ON rps.PostId = rpc.PostId AND rpc.ChangeRank = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT TOP 1 PostTypeId FROM Posts WHERE Id = rps.PostId)
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, rps.PostId, rps.TotalBounty, rps.VoteCount, rps.Rank, rpc.ChangeRank, ub.BadgeCount
ORDER BY 
    rps.TotalBounty DESC, u.Reputation DESC;
