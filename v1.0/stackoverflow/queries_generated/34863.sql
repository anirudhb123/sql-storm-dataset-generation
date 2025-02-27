WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, 1 AS HierarchyLevel
    FROM Tags
    WHERE IsModeratorOnly = 0
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, r.HierarchyLevel + 1
    FROM Tags t
    JOIN RecursiveTagHierarchy r ON t.ExcerptPostId = r.Id
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           u.CreationDate,
           u.DisplayName,
           u.Views,
           u.UpVotes,
           u.DownVotes,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.DisplayName, u.Views, u.UpVotes, u.DownVotes
),
PostHistorySummary AS (
    SELECT ph.PostId,
           COUNT(DISTINCT ph.Id) AS EditCount,
           MAX(ph.CreationDate) AS LastEditDate,
           STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 24)
    GROUP BY ph.PostId
),
VoteSummary AS (
    SELECT p.Id AS PostId,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT u.DisplayName,
       u.Reputation,
       u.PostCount,
       u.QuestionsCount,
       u.AnswersCount,
       th.TagName,
       ph.EditCount,
       ph.LastEditDate,
       ph.EditComments,
       vs.UpVotes,
       vs.DownVotes
FROM UserStats u
JOIN Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN RecursiveTagHierarchy th ON p.Tags LIKE '%' || th.TagName || '%'
LEFT JOIN PostHistorySummary ph ON p.Id = ph.PostId
LEFT JOIN VoteSummary vs ON p.Id = vs.PostId
WHERE u.Reputation >= 100
  AND (vs.UpVotes - vs.DownVotes) > 2
ORDER BY u.Reputation DESC, p.ViewCount DESC
LIMIT 10;
