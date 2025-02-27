
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR AND 
        p.Score > 0
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeCount, 0) AS RecentBadgeCount,
        COALESCE(rb.BadgeNames, 'None') AS RecentBadges,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentTotal,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR) AS VoteTotal
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.RecentBadgeCount,
    u.RecentBadges,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount
FROM 
    UserActivity u
JOIN 
    RankedPosts p ON u.UserId = p.PostId
WHERE 
    p.PostRank <= 5 
ORDER BY 
    u.Reputation DESC, p.CreationDate DESC
LIMIT 100;
