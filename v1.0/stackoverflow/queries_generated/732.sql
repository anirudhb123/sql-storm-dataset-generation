WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.Count, 0)) AS TotalVotes,
        MAX(u.LastAccessDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    COALESCE(rp.Title, 'No recent posts') AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    COALESCE(cp.LastClosedDate, 'Not closed') AS LastClosedPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    ua.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    ua.TotalVotes DESC,
    ua.LastActive DESC;
