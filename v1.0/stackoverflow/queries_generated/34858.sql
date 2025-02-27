WITH RecursivePostHierarchy AS (
    -- Base case: Select all questions
    SELECT Id, Title, OwnerUserId, AcceptedAnswerId, 1 AS Level
    FROM Posts
    WHERE PostTypeId = 1

    UNION ALL

    -- Recursive case: Join with Posts to find answers
    SELECT p.Id, p.Title, p.OwnerUserId, p.AcceptedAnswerId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
    WHERE p.PostTypeId = 2
),
UserReputation AS (
    -- Retrieve users and their reputation
    SELECT Id AS UserId, Reputation, DisplayName
    FROM Users
    WHERE Reputation > 1000
),
PostStats AS (
    -- Aggregate statistics for each post
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
PostHistorySummary AS (
    -- Get post edit history
    SELECT 
        ph.PostId, 
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN ph.CreationDate END) AS LastEditedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(*) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    MAX(u.DisplayName) AS OwnerDisplayName,
    phs.LastEditedDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(rph.Level, 0) AS AnswerLevel,
    ps.EditCount,
    phs.ClosureCount,
    u.Reputation
FROM Posts p
JOIN PostStats ps ON p.Id = ps.Id
LEFT JOIN UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN PostHistorySummary phs ON p.Id = phs.PostId
LEFT JOIN RecursivePostHierarchy rph ON p.AcceptedAnswerId = rph.Id
GROUP BY p.Id, p.Title, ps.CommentCount, ps.VoteCount, u.Reputation, phs.LastEditedDate, AnswerLevel
ORDER BY u.Reputation DESC, ps.VoteCount DESC;
