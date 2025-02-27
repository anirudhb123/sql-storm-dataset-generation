WITH RecursiveUsers AS (
    -- CTE to find all users who voted on posts, with their reputation
    SELECT u.Id, u.Reputation, u.DisplayName, u.CreationDate
    FROM Users u
    WHERE u.Reputation > 1000
    UNION ALL
    SELECT u.Id, u.Reputation, u.DisplayName, u.CreationDate
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    WHERE v.CreationDate > (SELECT MAX(CreationDate) FROM Votes) - INTERVAL '30 days'
),

PostVoteStats AS (
    -- CTE to calculate vote statistics for posts including current and historical votes
    SELECT p.Id AS PostId,
           COUNT(v.Id) AS TotalVotes,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

PostHistoryStats AS (
    -- CTE to aggregate post history types related to edits on questions
    SELECT ph.PostId,
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
           MIN(ph.CreationDate) AS FirstEditDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE p.PostTypeId = 1
    GROUP BY ph.PostId
)

SELECT pu.DisplayName AS VoterName,
       pu.Reputation AS VoterReputation,
       ps.PostId,
       ps.TotalVotes,
       ps.UpVotes,
       ps.DownVotes,
       phs.EditCount AS TotalEdits,
       phs.CloseReopenCount,
       phs.FirstEditDate,
       p.Title,
       CASE 
           WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
           WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
           ELSE 'Open'
       END AS PostStatus,
       STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM PostVoteStats ps
JOIN Posts p ON ps.PostId = p.Id
JOIN RecursiveUsers pu ON pu.Id IN (SELECT v.UserId FROM Votes v WHERE v.PostId = p.Id)
LEFT JOIN PostHistoryStats phs ON phs.PostId = ps.PostId
LEFT JOIN Tags t ON t.WikiPostId = p.Id
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY pu.Id, ps.PostId, phs.EditCount, phs.CloseReopenCount, phs.FirstEditDate, p.Title
ORDER BY ps.TotalVotes DESC, pu.Reputation DESC;
