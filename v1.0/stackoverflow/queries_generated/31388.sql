WITH RecursiveCTE AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Score, 
           p.CreationDate,
           0 AS Level,
           CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions

    UNION ALL

    SELECT p.Id AS PostId, 
           p.Title, 
           p.Score, 
           p.CreationDate,
           r.Level + 1,
           CAST(r.Path + ' -> ' + p.Title AS VARCHAR(MAX)) AS Path
    FROM Posts p
    JOIN Posts r ON p.ParentId = r.Id
    WHERE p.PostTypeId = 2 -- Only Answers
),
PostStats AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.OwnerUserId
),
PostHistoryStats AS (
    SELECT ph.PostId,
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
           MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(phs.ClosedDate, 'No') AS ClosedDate,
    COALESCE(phs.ReopenedDate, 'No') AS ReopenedDate,
    r.Level,
    r.Path,
    DATEDIFF(DAY, r.CreationDate, GETDATE()) AS DaysSinceCreation
FROM RecursiveCTE r
JOIN PostStats ps ON r.PostId = ps.PostId
LEFT JOIN PostHistoryStats phs ON r.PostId = phs.PostId
WHERE ps.CommentCount > 5 -- At least 5 comments on the question
AND r.Level <= 3 -- To limit the recursion depth
ORDER BY ps.UpVotes DESC, 
         ps.BadgeCount DESC, 
         r.Score DESC;
