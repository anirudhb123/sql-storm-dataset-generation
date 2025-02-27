WITH RecursivePostHierarchy AS (
    SELECT Id, Title, Score, AcceptedAnswerId, ParentId, CreationDate, OwnerUserId,
           CAST(Title AS VARCHAR(300)) AS FullTitle,
           0 AS Level
    FROM Posts
    WHERE ParentId IS NULL   -- Get top-level posts (questions)
    
    UNION ALL
    
    SELECT p.Id, p.Title, p.Score, p.AcceptedAnswerId, p.ParentId, p.CreationDate, p.OwnerUserId,
           CAST(r.FullTitle || ' -> ' || p.Title AS VARCHAR(300)) AS FullTitle,
           r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostDetails AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Score, 
           p.ViewCount, 
           p.AnswerCount,
           COALESCE(a.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
           u.DisplayName AS OwnerDisplayName,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id  -- Left join to get accepted answer
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, a.Title, u.DisplayName
),
PostVoteCounts AS (
    SELECT PostId, 
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Votes
    GROUP BY PostId
),
RecentPostHistory AS (
    SELECT ph.PostId,
           MAX(ph.CreationDate) AS LastEditDate,
           STRING_AGG(DISTINCT pht.Name, ', ') AS ChangesMade
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Posts modified in the last year
    GROUP BY ph.PostId
)
SELECT pd.PostId, 
       pd.Title,
       pd.Score,
       pd.ViewCount,
       pd.AnswerCount,
       pd.AcceptedAnswerTitle,
       pd.OwnerDisplayName,
       COALESCE(pvc.UpVoteCount, 0) AS UpVoteCount,
       COALESCE(pvc.DownVoteCount, 0) AS DownVoteCount,
       COALESCE(rph.LastEditDate, 'No edits') AS LastEditDate,
       COALESCE(rph.ChangesMade, 'No changes') AS ChangesMade,
       rh.FullTitle AS Hierarchy
FROM PostDetails pd
LEFT JOIN PostVoteCounts pvc ON pd.PostId = pvc.PostId
LEFT JOIN RecentPostHistory rph ON pd.PostId = rph.PostId
JOIN RecursivePostHierarchy rh ON pd.PostId = rh.Id
ORDER BY pd.Score DESC, pd.ViewCount DESC;
