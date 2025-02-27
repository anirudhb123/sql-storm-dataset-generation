WITH UserBadgeStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalUpVotes - TotalDownVotes AS NetVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalPosts DESC, NetVotes DESC) AS ActivityRank
    FROM UserBadgeStats
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        COALESCE(HEADER.NAME, 'Unknown') AS PostTypeName
    FROM Posts p
    LEFT JOIN PostTypes header ON p.PostTypeId = header.Id
)
SELECT 
    u.DisplayName,
    u.TotalUpVotes,
    u.TotalDownVotes,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    ps.CommentCount,
    ps.PostTypeName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.ActivityRank
FROM MostActiveUsers u
JOIN PostStatistics ps ON ps.UserId = u.UserId
WHERE u.ActivityRank <= 10
AND p.CreationDate >= NOW() - INTERVAL '1 month'
ORDER BY u.ActivityRank, ps.CommentCount DESC;
