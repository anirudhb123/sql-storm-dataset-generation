WITH UserReputation AS (
    SELECT
        Id,
        Reputation,
        CreationDate,
        CASE
            WHEN Reputation BETWEEN 0 AND 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 101 AND 1000 THEN 'Intermediate'
            WHEN Reputation > 1000 THEN 'Expert'
        END AS ReputationLevel
    FROM Users
),
PostStatistics AS (
    SELECT
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
BadgesByUser AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
UserPosts AS (
    SELECT
        u.Id AS UserId,
        COALESCE(ps.Questions, 0) AS TotalQuestions,
        COALESCE(ps.Answers, 0) AS TotalAnswers,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.BadgeNames, 'None') AS BadgeNames,
        u.Reputation,
        u.ReputationLevel
    FROM UserReputation u
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN BadgesByUser bs ON u.Id = bs.UserId
)
SELECT
    up.UserId,
    up.TotalQuestions,
    up.TotalAnswers,
    up.BadgeCount,
    up.BadgeNames,
    CASE
        WHEN up.BadgeCount > 5 THEN 'Active Contributor'
        WHEN up.BadgeCount BETWEEN 1 AND 5 THEN 'Active'
        ELSE 'Inactive'
    END AS EngagementLevel,
    up.Reputation,
    up.ReputationLevel,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY up.Reputation) OVER () AS MedianReputation,
    CASE
        WHEN up.TotalQuestions > 10 AND up.BadgeCount = 0 THEN 'More badges needed'
        ELSE NULL
    END AS Feedback
FROM UserPosts up
WHERE up.TotalQuestions > 0
ORDER BY up.TotalQuestions DESC, up.Reputation DESC
LIMIT 50;

-- Including outer joins and NULL logic in the calculations.
WITH CTE_Posts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.Title, v.UpVotes, v.DownVotes
)
SELECT
    pp.PostId,
    pp.Title,
    pp.UpVotes,
    pp.DownVotes,
    pp.CommentCount,
    pp.HasAcceptedAnswer,
    (pp.UpVotes - pp.DownVotes) AS NetVotes,
    ROW_NUMBER() OVER (PARTITION BY pp.OwnerUserId ORDER BY pp.HasAcceptedAnswer DESC) AS RankByAcceptance
FROM CTE_Posts pp
WHERE pp.CommentCount > 0
  AND (pp.HasAcceptedAnswer = 0 OR pp.CommentCount > 5)
  AND pp.NetVotes > 0
ORDER BY pp.NetVotes DESC;
