WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 
            CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END 
            ELSE 0 END) OVER (PARTITION BY p.Id) AS VoteBalance
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS ActivePostCount
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) >= 3
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.CommentCount,
    rp.Score AS PostScore,
    rp.VoteBalance,
    CASE 
        WHEN up.ActivePostCount IS NOT NULL THEN 'Active Contributor' 
        ELSE 'Newcomer' 
    END AS UserStatus,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = up.UserId) AS BadgeCount,
    COALESCE((SELECT STRING_AGG(pt.Name, ', ') 
              FROM PostHistory ph 
              JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id 
              WHERE ph.PostId = rp.PostId), 'No history') AS PostHistorySummary
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveUsers up ON rp.PostId = up.UserId
WHERE 
    rp.RecentPostRank = 1 
    AND rp.VoteBalance > 0 
ORDER BY 
    rp.Score DESC 
LIMIT 10;

This SQL query integrates various advanced SQL constructs such as Common Table Expressions (CTEs), window functions, joins, and careful conditional logic to identify and rank posts from active users over the past year, while including relevant post history summaries and calculating vote balance to provide a comprehensive performance benchmarking of user contributions on the platform.
