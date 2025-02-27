WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, 1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 0
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, r.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.Id = r.Id
),
PostScoreRankings AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.Score > 0
),
ClosePostHistory AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseVoteCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(cph.CloseVoteCount, 0) AS TotalCloseVotes,
    psg.ScoreRank,
    ub.BadgeCount,
    STRING_AGG(rth.TagName, ', ') AS AssociatedTags,
    CASE
        WHEN p.Score > 10 THEN 'High'
        WHEN p.Score BETWEEN 1 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS PostScoreCategory
FROM Posts p
LEFT JOIN ClosePostHistory cph ON p.Id = cph.PostId
JOIN PostScoreRankings psg ON p.Id = psg.Id
LEFT JOIN UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN RecursiveTagHierarchy rth ON rth.Id = p.Id
GROUP BY p.Id, p.Title, p.CreationDate, TotalCloseVotes, psg.ScoreRank, ub.BadgeCount
ORDER BY psg.ScoreRank, p.Title;
