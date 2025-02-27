-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.AnswerCount
    FROM Posts p
),
AggregatePostStats AS (
    SELECT 
        u.UserId,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        AVG(ps.Score) AS AvgPostScore,
        AVG(ps.ViewCount) AS AvgPostViews
    FROM UserStatistics u
    LEFT JOIN PostStatistics ps ON u.UserId = ps.OwnerUserId
    GROUP BY u.UserId
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.UpVotes,
    us.DownVotes,
    aps.TotalPosts,
    aps.AvgPostScore,
    aps.AvgPostViews,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM UserStatistics us
LEFT JOIN AggregatePostStats aps ON us.UserId = aps.UserId
ORDER BY us.Reputation DESC;
