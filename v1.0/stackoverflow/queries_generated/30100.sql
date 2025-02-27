WITH RECURSIVE PostHierarchy AS (
    SELECT Id, ParentId, Title, CreationDate, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        (SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3)) AS Score
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.CommentCount,
    pp.UpVotes AS TotalUpVotes,
    pp.DownVotes AS TotalDownVotes,
    pp.Score,
    ph.Level
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
JOIN RankedPosts pp ON u.Id = pp.OwnerUserId
LEFT JOIN PostHierarchy ph ON pp.Id = ph.Id
WHERE 
    pp.PostRank = 1
    AND pp.ViewCount > 100
ORDER BY pp.Score DESC, pp.ViewCount DESC
LIMIT 50;
