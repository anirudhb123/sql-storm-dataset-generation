WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId, 
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
), PostAnalytics AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        COALESCE(up.Reputation, 0) AS UserReputation,
        COALESCE(up.BadgeCount, 0) AS BadgeCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation up ON u.Id = up.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.UserReputation,
    pa.BadgeCount,
    pa.CloseCount
FROM 
    PostAnalytics pa
WHERE 
    (pa.UserReputation > 1000 OR pa.BadgeCount > 5)
    AND pa.CloseCount = 0
ORDER BY 
    pa.Score DESC, 
    pa.UserReputation DESC
LIMIT 50;

-- Additional Queries to Benchmark Performance
SELECT 
    COUNT(*) AS ActiveUsers,
    SUM(CASE WHEN Reputation > 1000 THEN 1 ELSE 0 END) AS HighReputationUsers
FROM 
    Users
WHERE 
    LastAccessDate >= NOW() - INTERVAL '1 month';

SELECT 
    pt.Name, 
    COUNT(p.Id) AS PostCount
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
