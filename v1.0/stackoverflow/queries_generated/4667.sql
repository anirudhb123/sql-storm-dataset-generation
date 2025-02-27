WITH UserVoteStats AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
AcceptedAnswers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS AcceptedCount
    FROM Posts
    WHERE AcceptedAnswerId IS NOT NULL
    GROUP BY OwnerUserId
),
PostTypeCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TypeCount
    FROM Posts
    GROUP BY PostTypeId
),
ClosedPostStats AS (
    SELECT 
        PostId,
        COUNT(DISTINCT UserId) AS CloseVotes
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.LastAccessDate,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(asw.AcceptedCount, 0) AS AcceptedAnswers,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ps.TypeCount, 0) AS TotalPosts,
    COALESCE(cps.CloseVotes, 0) AS CloseVoteCount
FROM Users u
LEFT JOIN UserVoteStats vs ON u.Id = vs.UserId
LEFT JOIN AcceptedAnswers asw ON u.Id = asw.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostTypeCounts ps ON ps.PostTypeId = (SELECT MIN(Id) FROM PostTypes) -- Example of a correlated subquery
LEFT JOIN ClosedPostStats cps ON cps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id) 
WHERE u.Reputation > 100 
ORDER BY u.Reputation DESC
FETCH FIRST 100 ROWS ONLY;
