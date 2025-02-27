WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) as Rank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u 
        LEFT JOIN Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),

PostStatistics AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),

ClosedPostsStats AS (
    SELECT 
        ph.UserId AS CloserUserId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(DISTINCT c.Comment, '; ') AS CloseComments
    FROM 
        PostHistory ph 
        JOIN CloseReasonTypes crt ON ph.Comment = crt.Id::text
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.UserId
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.Rank,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    COALESCE(cps.CloseCount, 0) AS CloseCount,
    COALESCE(cps.CloseComments, 'No comments') AS CloseComments
FROM 
    RankedUsers ru
LEFT JOIN 
    PostStatistics ps ON ru.UserId = ps.OwnerUserId
LEFT JOIN 
    ClosedPostsStats cps ON ru.UserId = cps.CloserUserId
WHERE 
    ru.Reputation > 100 AND 
    (COALESCE(ps.PostCount, 0) > 0 OR cps.CloseCount > 0)
ORDER BY 
    ru.Rank, ru.Reputation DESC;

-- Additional complex subquery for determining badge eligibility
WITH EligibleBadges AS (
    SELECT 
        u.Id AS UserId,
        CASE 
            WHEN SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) > 0 
                THEN 'Gold Badge Holder'
            WHEN SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) > 5 
                THEN 'Silver Badge Enthusiast'
            WHEN SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) > 10 
                THEN 'Bronze Badge Collector'
            ELSE 'No Significant Badges' 
        END AS BadgeStatus
    FROM 
        Users u 
    LEFT JOIN Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    eb.BadgeStatus
FROM 
    RankedUsers ru 
JOIN 
    EligibleBadges eb ON ru.UserId = eb.UserId
WHERE 
    ru.Rank < 100;

-- Including a bizarre NULL logic case in an external query
SELECT 
    DISTINCT u.DisplayName,
    CASE 
        WHEN u.Location IS NOT NULL THEN u.Location
        ELSE 'Location Unknown'
    END AS UserLocation,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id AND p.ViewCount IS NULL)
            THEN 'Has Posts with Unknown Views'
        ELSE 'All Posts Have Known Views' 
    END AS ViewStatus
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    u.Id;
