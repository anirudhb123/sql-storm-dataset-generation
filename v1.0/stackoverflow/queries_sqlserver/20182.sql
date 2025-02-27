
WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.Score,
           p.ViewCount,
           p.Tags,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
           SUM(p.ViewCount) OVER (PARTITION BY p.OwnerUserId) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS date)
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           u.DisplayName,
           COUNT(b.Id) AS BadgeCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
           MAX(ph.CreationDate) AS LastEventDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
DetailedPosts AS (
    SELECT rp.Id AS PostId,
           rp.Title,
           rp.Score,
           rp.ViewCount,
           us.DisplayName AS OwnerDisplayName,
           us.Reputation AS OwnerReputation,
           COALESCE(ph.CloseCount, 0) AS CloseCount,
           COALESCE(ph.DeleteCount, 0) AS DeleteCount,
           ph.LastEventDate,
           rp.TotalViews,
           rp.Tags
    FROM RankedPosts rp
    JOIN Users us ON us.Id = (SELECT TOP 1 p.OwnerUserId FROM Posts p WHERE p.Id = rp.Id)
    LEFT JOIN PostHistoryDetails ph ON ph.PostId = rp.Id
    WHERE (rp.RankByScore <= 3 OR rp.TotalViews > 100)
)
SELECT dp.PostId,
       dp.Title,
       dp.Score,
       dp.ViewCount,
       dp.OwnerDisplayName,
       dp.OwnerReputation,
       dp.CloseCount,
       dp.DeleteCount,
       dp.LastEventDate,
       dp.Tags,
       CASE
           WHEN dp.CloseCount > 0 THEN 'Closed'
           WHEN dp.DeleteCount > 0 THEN 'Deleted'
           ELSE 'Active'
       END AS PostStatus,
       STRING_AGG(DISTINCT t.TagName, ',') AS RelatedTags
FROM DetailedPosts dp
LEFT JOIN Tags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(dp.Tags, ','))
WHERE dp.OwnerReputation > (SELECT AVG(Reputation) FROM Users)
GROUP BY dp.PostId, dp.Title, dp.Score, dp.ViewCount, dp.OwnerDisplayName, dp.OwnerReputation,
         dp.CloseCount, dp.DeleteCount, dp.LastEventDate, dp.Tags
ORDER BY dp.Score DESC, dp.CloseCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
