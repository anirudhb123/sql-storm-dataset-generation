WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ur.Reputation,
    ur.BadgeCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High Reputation User'
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User'
    END AS ReputationCategory
FROM 
    RecentPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.rn = 1 -- Get only the most recent post per user
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 50 ROWS ONLY
UNION ALL
SELECT 
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS Reputation,
    NULL AS BadgeCount,
    NULL AS UpVotes,
    NULL AS DownVotes,
    NULL AS TotalVotes,
    'Summary' AS ReputationCategory
FROM 
    DUAL
