WITH RecursivePostCTE AS (
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        CreationDate,
        Score,
        1 AS Level
    FROM Posts
    WHERE ParentId IS NULL  -- Starting with top-level questions (no parent)

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        Level + 1 AS Level
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.PostId  -- Recursive join
),

PostScoreSummary AS (
    SELECT 
        PostId,
        COUNT(*) AS NumberOfVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),

UserBadgeSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)

SELECT 
    p.Title,
    p.CreationDate,
    r.Level,
    ps.NumberOfVotes,
    ps.UpVotes,
    ps.DownVotes,
    u.DisplayName AS OwnerName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM RecursivePostCTE r
JOIN Posts p ON r.PostId = p.Id
LEFT JOIN PostScoreSummary ps ON p.Id = ps.PostId
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserBadgeSummary ub ON u.Id = ub.UserId
WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  -- Posts created in the last 30 days
  AND COALESCE(ps.UpVotes - ps.DownVotes, 0) > 10  -- Only include posts with a net score greater than 10
ORDER BY r.Level, ps.NumberOfVotes DESC;
