
WITH RankedUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),

ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        MAX(CASE WHEN Ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN PostHistory Ph ON p.Id = Ph.PostId
    LEFT JOIN (
        SELECT 
            p.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
        INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON p.Id = t.PostId
    GROUP BY p.Id, p.Title, p.Score, p.AnswerCount, p.CommentCount, p.CreationDate, p.ViewCount, p.OwnerUserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
)

SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.Views,
    ru.BadgeCount,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    COUNT(DISTINCT ap.Id) AS TotalActivePosts,
    SUM(CASE WHEN ap.IsClosed = 1 THEN 1 ELSE 0 END) AS ClosedPosts,
    SUM(ua.TotalPosts) AS PostsCreated,
    SUM(ua.TotalBounty) AS TotalBountyReward,
    SUM(ua.UpVotes) AS TotalUpVotes,
    SUM(ua.DownVotes) AS TotalDownVotes,
    GROUP_CONCAT(DISTINCT ap.Tags SEPARATOR '; ') AS AllPostTags
FROM RankedUsers ru
JOIN ActivePosts ap ON ru.Id = ap.OwnerUserId
JOIN UserActivity ua ON ru.Id = ua.UserId
GROUP BY ru.Id, ru.DisplayName, ru.Reputation, ru.Views, ru.BadgeCount, ru.GoldBadges, ru.SilverBadges, ru.BronzeBadges
ORDER BY ru.Reputation DESC, TotalActivePosts DESC
LIMIT 10;
