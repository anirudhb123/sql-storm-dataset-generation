WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, IsModeratorOnly, IsRequired,
           1 AS HierarchyLevel
    FROM Tags
    WHERE IsRequired = 1
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.IsModeratorOnly, t.IsRequired,
           th.HierarchyLevel + 1
    FROM Tags t
    JOIN TagHierarchy th ON t.WikiPostId = th.Id
),
PostVoteSummary AS (
    SELECT p.Id AS PostId, 
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, 
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostHistoryDetails AS (
    SELECT p.Id AS PostId, 
           ph.UserId,
           ph.CreationDate,
           ph.Comment,
           ph.PostHistoryTypeId,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id 
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    u.DisplayName AS LastEditorName,
    u.Reputation,
    th.TagName,
    th.Count AS TagCount,
    phd.CreationDate AS LastEditDate,
    CASE 
        WHEN phd.EditRank = 1 THEN 'Most Recent Edit'
        ELSE 'Earlier Edit'
    END AS EditStatus,
    (SELECT SUM(Count) FROM Tags) AS TotalTags
FROM Posts p
LEFT JOIN PostVoteSummary pv ON p.Id = pv.PostId
LEFT JOIN Users u ON p.LastEditorUserId = u.Id
LEFT JOIN TagHierarchy th ON th.Id IN (SELECT UNNEST(string_to_array(p.Tags, ',')))  
LEFT JOIN PostHistoryDetails phd ON phd.PostId = p.Id
WHERE p.PostTypeId = 1 -- Questions
  AND (p.CreationDate < NOW() - INTERVAL '1 year' OR pv.UpVotes > 10)
ORDER BY p.ViewCount DESC, UpVotes DESC
LIMIT 100;
