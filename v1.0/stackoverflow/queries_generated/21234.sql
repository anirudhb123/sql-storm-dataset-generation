WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.AssumedClosure,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CONCAT_WS(': ', u.DisplayName, ph.Comment), '; ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.LatestBadgeDate,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    coalesce(cph.CloseCount, 0) AS TotalCloseActions,
    coalesce(cph.CloseReasons, 'No closures') AS ClosureDetails
FROM 
    UserStatistics us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPostHistory cph ON cph.PostId = rp.PostId
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND us.BadgeCount > 0
ORDER BY 
    us.Reputation DESC,
    rp.CreationDate DESC
LIMIT 100;
