
WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        b.Date,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM Users u 
    JOIN Badges b ON u.Id = b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ub.BadgeName,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    pi.CommentCount,
    pi.UpvoteCount,
    pi.DownvoteCount,
    pi.TotalBounty,
    CASE 
        WHEN pi.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Comments Present'
    END AS CommentStatus
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId AND ub.BadgeRank = 1
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN PostInteractions pi ON rp.PostId = pi.PostId
WHERE u.CreationDate < CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
GROUP BY u.Id, u.DisplayName, u.Reputation, ub.BadgeName, rp.Title, rp.CreationDate, pi.CommentCount, pi.UpvoteCount, pi.DownvoteCount, pi.TotalBounty
ORDER BY u.Reputation DESC, RecentPostDate DESC
LIMIT 50;
