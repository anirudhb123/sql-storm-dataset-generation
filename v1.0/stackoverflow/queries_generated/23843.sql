WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        COALESCE(v.UpVotes, 0) AS UpVotes, 
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COUNT(DISTINCT CASE WHEN b.TagBased = 0 THEN b.Id END) AS NonTagBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened' 
            ELSE 'Other' 
        END AS ActionType,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS ActionCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
      AND ph.CreationDate >= NOW() - INTERVAL '1 month'
), 
AggregatedData AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.UpVotes,
        r.DownVotes,
        u.DisplayName,
        COALESCE(c.ActionCount, 0) AS ClosureCount,
        CASE 
            WHEN r.Score >= 10 THEN 'Highly Active' 
            ELSE 'Less Active' 
        END AS ActivityLevel
    FROM RankedPosts r
    JOIN UserStats u ON r.PostId = (
        SELECT p.Id
        FROM Posts p 
        WHERE p.OwnerUserId = u.UserId 
        ORDER BY p.CreationDate DESC 
        LIMIT 1
    )
    LEFT JOIN ClosedPosts c ON r.PostId = c.PostId
    WHERE r.rn = 1
)

SELECT 
    a.PostId,
    a.Title,
    a.Score,
    a.UpVotes,
    a.DownVotes,
    a.DisplayName,
    a.ClosureCount,
    a.ActivityLevel
FROM AggregatedData a 
WHERE a.ClosureCount > 0 
  OR (a.UpVotes - a.DownVotes) > 5 
ORDER BY a.Score DESC, a.ClosureCount DESC;
This query consists of multiple Common Table Expressions (CTEs) to derive interest from users and posts, correlated subqueries to assess user badges, and handle performance with various filtering and aggregation strategies. It also utilizes window functions to rank posts, and conditional logic to categorize user and post activity levels. The final selection filters based on a specific logic related to post engagement and closure counts.
