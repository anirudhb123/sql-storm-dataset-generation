WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),

ClosePostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened 
    GROUP BY ph.PostId
),

PostWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.VoteCount, 0) AS VoteCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
)

SELECT 
    rph.PostId,
    rph.Title,
    rph.CreationDate,
    ur.DisplayName AS TopUser,
    ur.Reputation AS UserReputation,
    cp.CloseCount,
    cp.FirstCloseDate,
    pw.UpVotes,
    pw.DownVotes,
    pw.VoteCount
FROM RecursivePostHierarchy rph
LEFT JOIN UserReputation ur ON ur.Rank = 1  -- Get top user by reputation
LEFT JOIN ClosePostHistory cp ON cp.PostId = rph.PostId
LEFT JOIN PostWithVotes pw ON pw.PostId = rph.PostId
WHERE 
    rph.Level = 1  -- Only retrieve questions
ORDER BY 
    rph.CreationDate DESC;

This SQL query first establishes a recursive common table expression (CTE) to explore the hierarchy of posts by linking questions with their respective answers. It then calculates user reputations, the close status of posts, and the associated vote counts. At the end, it combines all of this information, focusing only on those top-level questions, to produce a comprehensive and detailed output that includes interactions between posts, users, voting, and closure history.
