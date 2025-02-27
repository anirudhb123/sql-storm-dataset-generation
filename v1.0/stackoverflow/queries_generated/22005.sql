WITH RecursivePostHistory AS (
    SELECT p.Id AS PostId, ph.CreationDate, ph.PostHistoryTypeId, ph.UserId, ph.Comment,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn,
           LEAD(ph.CreationDate) OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS NextHistoryDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
),
TagDetails AS (
    SELECT t.TagName, COUNT(p.Id) AS PostCount, SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = p.Id
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY t.TagName
),
UserReputation AS (
    SELECT u.Id AS UserId, 
           SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
           MAX(u.Reputation) AS HighestReputation
    FROM Users u
    JOIN PostHistory ph ON u.Id = ph.UserId
    GROUP BY u.Id
),
InterestingPosts AS (
    SELECT p.Id, p.Title, 
           COUNT(DISTINCT v.Id) AS VoteCount, 
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY p.Id, p.Title
    HAVING COUNT(DISTINCT v.Id) > 5 AND (MAX(ph.CreationDate) - MIN(ph.CreationDate)) < INTERVAL '1 month' 
    ORDER BY VoteCount DESC
),
FinalResult AS (
    SELECT ip.PostId, ip.Title, ip.VoteCount, ip.IsClosed, ud.UserId, ud.CloseReopenCount, 
           ud.HighestReputation, td.PostCount, td.TotalBounty
    FROM InterestingPosts ip
    LEFT JOIN UserReputation ud ON ud.UserId = ip.PostId
    LEFT JOIN TagDetails td ON td.TagName IN (SELECT UNNEST(string_to_array(ip.Tags, ', ')))
)
SELECT fr.*, 
       CASE 
           WHEN fr.IsClosed = 1 THEN 'Closed'
           ELSE 'Open'
       END AS Status,
       ROW_NUMBER() OVER (ORDER BY fr.VoteCount DESC, fr.HighestReputation DESC) AS Ranking
FROM FinalResult fr
WHERE fr.TotalBounty > 0 OR fr.CloseReopenCount > 0
ORDER BY fr.Ranking
LIMIT 100;
