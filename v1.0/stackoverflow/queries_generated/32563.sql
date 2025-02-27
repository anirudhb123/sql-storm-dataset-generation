WITH RecursivePostCTE AS (
    SELECT Id, Title, AcceptedAnswerId, CreationDate, OwnerUserId, 0 AS Level
    FROM Posts
    WHERE PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT p.Id, p.Title, p.AcceptedAnswerId, p.CreationDate, p.OwnerUserId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 4 THEN 1 END) AS OffensiveVotes
    FROM Votes
    GROUP BY PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(u.UpVotes) > 0
    ORDER BY TotalUpVotes DESC
    LIMIT 10
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosed
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)

SELECT 
    r.Id AS QuestionId, 
    r.Title AS QuestionTitle, 
    r.OwnerUserId,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes, 
    COUNT(DISTINCT c.Id) AS CommentCount,
    MIN(cpu.FirstClosed) AS FirstCloseDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM RecursivePostCTE r
LEFT JOIN PostVoteSummary ps ON r.Id = ps.PostId
LEFT JOIN Comments c ON r.Id = c.PostId
LEFT JOIN ClosedPostHistory cpu ON r.Id = cpu.PostId
JOIN Users u ON r.OwnerUserId = u.Id
WHERE r.Level = 0  -- Getting only top-level questions
GROUP BY 
    r.Id, r.Title, r.OwnerUserId, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT c.Id) > 5  -- Questions with more than 5 comments
ORDER BY 
    TotalUpVotes DESC, OwnerReputation DESC;
