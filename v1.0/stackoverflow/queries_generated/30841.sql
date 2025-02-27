WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        UserId, 
        MAX(CreationDate) AS LastActiveDate
    FROM Comments
    GROUP BY UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalPosts,
    ups.QuestionsCount,
    ups.AnswersCount,
    ups.AvgPostScore,
    ra.LastActiveDate,
    COALESCE(ub.TotalBadges, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
FROM UserPostStats ups
LEFT JOIN RecentActivity ra ON ups.UserId = ra.UserId
LEFT JOIN UserBadges ub ON ups.UserId = ub.UserId
WHERE ups.Reputation > 100
ORDER BY ups.TotalPosts DESC, ups.Reputation DESC
FETCH FIRST 10 ROWS ONLY;

-- Query for obtaining users' most active tags
WITH ActiveTags AS (
    SELECT 
        u.Id AS UserId,
        t.TagName,
        COUNT(p.Id) AS PostsCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    CROSS JOIN LATERAL string_to_array(p.Tags, ',') AS tag
    JOIN Tags t ON trim(tag) = t.TagName
    WHERE p.CreationDate > now() - interval '1 year'
    GROUP BY u.Id, t.TagName
)
SELECT 
    UserId,
    TagName,
    PostsCount,
    RANK() OVER (PARTITION BY UserId ORDER BY PostsCount DESC) AS TagRank
FROM ActiveTags
WHERE TagRank <= 5;

-- Benchmarking query on post revisions and close reasons
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.Comment AS CloseReason,
    COUNT(ph.Id) AS RevisionCount,
    MIN(ph.CreationDate) AS FirstRevisionDate,
    MAX(ph.CreationDate) AS LastRevisionDate
FROM Posts p
JOIN PostHistory ph ON p.Id = ph.PostId
WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
GROUP BY p.Id, p.Title, ph.Comment
HAVING COUNT(ph.Id) > 5
ORDER BY RevisionCount DESC;

-- Using a union to compare users with identical scores and different levels of upvotes/downvotes
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS NetVotes
FROM Users u
LEFT JOIN Votes v ON u.Id = v.UserId
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING NetVotes > 0 AND Reputation > 1000
UNION ALL
SELECT 
    u2.Id,
    u2.DisplayName,
    u2.Reputation,
    SUM(v2.VoteTypeId = 2) AS UpVotes,
    SUM(v2.VoteTypeId = 3) AS DownVotes,
    SUM(v2.VoteTypeId = 2) - SUM(v2.VoteTypeId = 3) AS NetVotes
FROM Users u2
LEFT JOIN Votes v2 ON u2.Id = v2.UserId
GROUP BY u2.Id, u2.DisplayName,
