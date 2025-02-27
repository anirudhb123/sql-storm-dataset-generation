WITH RecursivePosts AS (
    SELECT Id, Title, ParentId, CreationDate, Score, 
           CAST(Title AS VARCHAR(300)) AS FullTitle, 
           0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.Score, 
           CAST(rp.FullTitle || ' -> ' || p.Title AS VARCHAR(300)), 
           Level + 1
    FROM Posts p
    JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
PostVoteSummary AS (
    SELECT PostId,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
PostHistorySummary AS (
    SELECT PostId,
           COUNT(CASE WHEN PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
           COUNT(CASE WHEN PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount
    FROM PostHistory
    WHERE CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY PostId
),
UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS TotalBadges,
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT rp.Id AS PostID,
       rp.FullTitle,
       rp.CreationDate,
       COALESCE(pvs.UpVotes, 0) AS UpVotes,
       COALESCE(pvs.DownVotes, 0) AS DownVotes,
       COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
       COALESCE(phs.CloseCount, 0) AS CloseCount,
       COALESCE(phs.DeleteCount, 0) AS DeleteCount,
       ub.TotalBadges AS UserTotalBadges,
       ub.GoldBadges,
       ub.SilverBadges,
       ub.BronzeBadges
FROM RecursivePosts rp
LEFT JOIN PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN PostHistorySummary phs ON rp.Id = phs.PostId
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE rp.Level = 0  -- Only top-level posts (Questions)
ORDER BY rp.CreationDate DESC
LIMIT 100;
