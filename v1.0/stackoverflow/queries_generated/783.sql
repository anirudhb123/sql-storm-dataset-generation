WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ua.PostCount > 5
ORDER BY 
    ua.UpVotes DESC, ua.DownVotes ASC
LIMIT 10;

WITH RECURSIVE CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        CAST('' AS varchar(255)) AS ReasonPath,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    UNION ALL
    SELECT 
        ph.PostId,
        ph.Comment,
        CAST(cr.ReasonPath || ' -> ' || ph.Comment AS varchar(255)),
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC)
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasons cr ON ph.PostId = cr.PostId
    WHERE 
        ph.PostHistoryTypeId = 11 AND cr.rn = 1
)
SELECT 
    p.Id,
    p.Title,
    ARRAY_AGG(DISTINCT cr.ReasonPath) AS ClosedReasons
FROM 
    Posts p
LEFT JOIN 
    CloseReasons cr ON p.Id = cr.PostId
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title;
