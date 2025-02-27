WITH RECURSIVE UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(vt.Score) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN (
        SELECT 
            p.OwnerUserId, 
            SUM(p.Score) AS Score 
        FROM Posts p 
        WHERE p.OwnerUserId IS NOT NULL
        GROUP BY p.OwnerUserId
    ) vt ON u.Id = vt.OwnerUserId
    GROUP BY u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        us.DisplayName,
        us.TotalVotes,
        us.TotalBounties,
        ROUND(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP - rp.CreationDate) / 86400.0, 2) AS DaysSinceCreation
    FROM RecentPosts rp
    JOIN UserScore us ON rp.OwnerUserId = us.UserId
    WHERE rp.rn = 1
)

SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.TotalVotes,
    ps.TotalBounties,
    ps.DaysSinceCreation,
    CASE 
        WHEN ps.Score > 100 THEN 'High-Scoring Post' 
        ELSE 'Regular Post' 
    END AS PostCategory,
    u.Locations AS UserLocation
FROM PostStats ps
JOIN Users u ON ps.UserId = u.Id
WHERE ps.TotalVotes > 10 
    OR ps.TotalBounties > 0
ORDER BY ps.Score DESC, ps.DaysSinceCreation ASC;

-- This query aggregates user activity and post statistics to help benchmark performance in terms of popular and engaging posts.
