WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(vote.VoteTypeId = 2) - SUM(vote.VoteTypeId = 3), 0) AS ReputationScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes vote ON vote.UserId = u.Id
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(ph.CreationDate) AS LatestActionDate,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name ELSE NULL END, ', ') AS CloseReasons,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY ph.PostId, ph.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(pd.CloseReasons, 'No close reasons') AS CloseReasons,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    LEFT JOIN PostHistoryDetails pd ON p.Id = pd.PostId
    WHERE p.CreationDate < NOW() AND p.PostTypeId IN (1, 2) -- Only questions and answers
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        ReputationScore,
        ROW_NUMBER() OVER (ORDER BY ReputationScore DESC) AS Rank
    FROM UserScore
    WHERE ReputationScore > 0
)
SELECT 
    u.UserId,
    u.DisplayName,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CloseReasons,
    COALESCE(u.ReputationScore, 0) AS UserReputation,
    t.Rank AS UserRank,
    CASE 
        WHEN ps.RankByScore IS NOT NULL THEN 1
        ELSE 0
    END AS IsTopPost
FROM PostStats ps
JOIN TopUsers t ON ps.PostId IN (
    SELECT p.Id
    FROM Posts p
    WHERE p.OwnerUserId = t.UserId
    ORDER BY p.Score DESC
    LIMIT 3
)
JOIN Users u ON ps.OwnerUserId = u.Id
WHERE ps.ViewCount > 1000 -- Only posts with a significant amount of views
  AND (ps.CloseReasons IS NULL OR ps.CloseReasons <> 'Nothing to see here')
ORDER BY UserReputation DESC, ps.Score DESC;
