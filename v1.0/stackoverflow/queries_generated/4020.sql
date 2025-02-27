WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS Favorites,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    uv.UpVotes,
    uv.DownVotes,
    uv.Favorites,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ps.Questions,
    ps.Answers,
    ps.CommentCount,
    ps.AvgScore,
    ps.HistoryCount,
    (CASE 
        WHEN uv.UpVotes > uv.DownVotes THEN 'Positively Active'
        WHEN uv.UpVotes < uv.DownVotes THEN 'Negatively Active'
        ELSE 'Neutral'
    END) AS EngagementLevel,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN Tags t ON t.Id = p.WikiPostId 
     WHERE p.OwnerUserId = u.Id) AS AssociatedTags
FROM Users u
LEFT JOIN UserVotes uv ON u.Id = uv.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
WHERE u.Reputation > 1000
ORDER BY uv.UpVotes DESC, uv.DownVotes ASC
LIMIT 100;
