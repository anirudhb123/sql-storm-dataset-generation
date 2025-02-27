WITH UserAggregate AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(u.Reputation) AS MaxReputation,
        AVG(u.Reputation) AS AvgReputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS Upvotes,  -- Only counting Upvotes
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter to recent posts
    GROUP BY p.Id, p.Title, p.PostTypeId, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT chr(pt.Id) || ': ' || pt.Name, ', ') AS CloseReason
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Only closed and reopened posts
    GROUP BY ph.PostId, ph.CreationDate
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.PostCount,
    ua.CommentCount,
    pm.PostId,
    pm.Title,
    pm.TotalComments,
    pm.Upvotes,
    cp.LastClosedDate,
    cp.CloseReason,
    CASE 
        WHEN ua.AvgReputation >= 1000 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserType,
    CASE 
        WHEN pm.TotalComments > 10 THEN 'Active Post'
        ELSE 'Less Active'
    END AS PostActivity,
    COALESCE(cp.LastClosedDate, 'No Close History') AS CloseHistory
FROM UserAggregate ua
INNER JOIN PostMetrics pm ON ua.UserId = pm.PostId
LEFT JOIN ClosedPosts cp ON pm.PostId = cp.PostId
WHERE ua.UserRank = 1  -- Only most recent users from UserAggregate
AND pm.RecentPostRank <= 5  -- Only top 5 recent posts per type
ORDER BY ua.Reputation DESC, pm.CreationDate DESC;
