WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of questions and answers
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers
),
UserVoteStats AS (
    -- CRT to calculate vote statistics for users
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    -- Summary of post history including the number of edits and types of actions
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ActionTypes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        p.Id
)
-- Final query to combine results
SELECT 
    rph.PostId,
    rph.Title,
    COUNT(DISTINCT rph.OwnerUserId) AS UniqueAuthors,
    COALESCE(vs.TotalVotes, 0) AS TotalVotes,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    phs.EditCount,
    phs.ActionTypes
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    UserVoteStats vs ON rph.OwnerUserId = vs.UserId
LEFT JOIN 
    PostHistorySummary phs ON rph.PostId = phs.PostId
GROUP BY 
    rph.PostId, rph.Title, vs.TotalVotes, vs.UpVotes, vs.DownVotes, phs.EditCount, phs.ActionTypes
ORDER BY 
    rph.Title;
