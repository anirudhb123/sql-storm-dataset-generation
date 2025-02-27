WITH RecursivePostCTE AS (
    -- Recursive CTE to get all answers for questions and their upvote counts
    SELECT p.Id AS PostId,
           p.OwnerUserId,
           p.AcceptedAnswerId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.AnswerCount,
           0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT p.Id,
           p.OwnerUserId,
           p.AcceptedAnswerId,
           q.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.AnswerCount,
           Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE q ON p.ParentId = q.PostId
    WHERE p.PostTypeId = 2 -- Answers
),
VoteStats AS (
    -- CTE to calculate vote statistics for each post
    SELECT PostId,
           COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(CASE WHEN VoteTypeId IN (10, 11) THEN 1 END) AS VoteChanges
    FROM Votes
    GROUP BY PostId
),
PostHistoryData AS (
    -- CTE to get post history details including close reasons
    SELECT ph.PostId,
           MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
           MIN(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalResults AS (
    -- Combining everything together
    SELECT rp.PostId,
           p.Title,
           p.CreationDate,
           p.ViewCount,
           COALESCE(vs.UpVotes, 0) AS UpVotes,
           COALESCE(vs.DownVotes, 0) AS DownVotes,
           COALESCE(ps.CloseReason, 'Not Closed') AS CloseReason,
           ps.ReopenDate,
           CONCAT(u.DisplayName, ' (', u.Reputation, ' Rpts)') AS UserInfo,
           rp.AnswerCount,
           rp.Score
    FROM RecursivePostCTE rp
    LEFT JOIN VoteStats vs ON rp.PostId = vs.PostId
    LEFT JOIN Posts p ON rp.PostId = p.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistoryData ps ON rp.PostId = ps.PostId
    WHERE rp.Level = 0 -- We only want questions, not answers
)
SELECT *,
       DENSE_RANK() OVER (PARTITION BY UserInfo ORDER BY Score DESC) AS UserRanking
FROM FinalResults
ORDER BY Score DESC, CreationDate DESC
LIMIT 100;
