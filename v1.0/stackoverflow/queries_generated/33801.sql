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
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.Score > 0
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '6 months'
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
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.CreationDate >= NOW() - INTERVAL '1 year') AS VoteTotal
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
    RankedPosts p ON u.UserId = p.PostId /* Mimicking a join on a user owning a post, simplified for demonstration */
WHERE 
    p.PostRank <= 5 
ORDER BY 
    u.Reputation DESC, p.CreationDate DESC
LIMIT 100;

-- Additional benchmarking: See how many posts each user has made and correlate to their recent activity
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.CreationDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts,
    AVG(COALESCE(rb.RecentBadgeCount, 0)) AS AvgRecentBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC; 
