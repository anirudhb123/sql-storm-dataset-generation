
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.LastActivityDate) AS LastActive
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ViewCount, 
        p.CreationDate,
        @rn := IF(@prevUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevUserId := p.OwnerUserId
    FROM Posts p, (SELECT @rn := 0, @prevUserId := NULL) AS vars
    ORDER BY p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.LastActive,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE ua.TotalPosts > 5
    AND ua.LastActive >= NOW() - INTERVAL 30 DAY
    AND (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ua.UserId AND v.VoteTypeId = 2) > 0
ORDER BY ua.LastActive DESC
LIMIT 20;
