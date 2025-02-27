WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(p.ViewCount) AS AvgViewsPerPost
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
BadgeStatistics AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
UserActivity AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.CommentCount, 0)) AS CommentCount,
        SUM(COALESCE(v.UpVoteCount, 0)) AS UpVoteCount,
        SUM(COALESCE(v.DownVoteCount, 0)) AS DownVoteCount
    FROM Users u
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) AS c ON c.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN (
        SELECT PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes 
        GROUP BY PostId
    ) AS v ON v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    GROUP BY u.Id
)
SELECT 
    ts.TagName,
    ts.TotalPosts,
    ts.TotalQuestions,
    ts.TotalAnswers,
    ts.TotalTagWikis,
    ts.TotalViews,
    ts.AvgViewsPerPost,
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.UpVoteCount,
    ua.DownVoteCount,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges,
    bs.TotalBadges
FROM TagStatistics ts
JOIN UserActivity ua ON ua.PostCount > 0
JOIN BadgeStatistics bs ON bs.UserId = ua.UserId
ORDER BY ts.TotalPosts DESC, ua.PostCount DESC;
