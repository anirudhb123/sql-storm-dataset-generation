
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        CONCAT(u.DisplayName, ' (', u.Reputation, ' pts)') AS UserProfile,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName 
         FROM Posts 
         JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n 
         ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1) t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes pv ON p.Id = pv.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ub.UserProfile,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ups.PostsCreated,
    ups.UpvotesReceived,
    ups.DownvotesReceived,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Tags
FROM 
    UserBadges ub
JOIN 
    UserPostStats ups ON ub.UserId = ups.UserId
LEFT JOIN 
    RecentPosts rp ON rp.CreationDate >= NOW() - INTERVAL 7 DAY
ORDER BY 
    ub.BadgeCount DESC, 
    ups.UpvotesReceived DESC
LIMIT 10;
