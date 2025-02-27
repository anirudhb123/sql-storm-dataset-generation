WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UpVotes,
    us.DownVotes,
    us.TotalPosts,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostDate,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - us.LastPostDate)) / 86400 AS DaysSinceLastPost
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts p ON us.UserId = p.PostId
WHERE 
    p.RecentPostRank = 1 
ORDER BY 
    us.Reputation DESC 
LIMIT 10
UNION
SELECT 
    NULL AS UserId,
    'Unattributed Posts' AS DisplayName,
    NULL AS Reputation,
    NULL AS UpVotes,
    NULL AS DownVotes,
    COUNT(*) AS TotalPosts,
    NULL AS RecentPostTitle,
    NULL AS RecentPostDate,
    NULL AS DaysSinceLastPost
FROM 
    Posts 
WHERE 
    OwnerUserId IS NULL 
HAVING 
    COUNT(*) > 10
ORDER BY 
    Reputation DESC;
