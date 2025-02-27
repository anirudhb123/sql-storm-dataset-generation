WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find parent posts and their associated answers
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL 

    SELECT 
        a.Id AS PostId,
        a.Title AS PostTitle,
        a.ParentId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy ph ON a.ParentId = ph.PostId
),
PostVoteStats AS (
    -- CTE to calculate upvote and downvote statistics for each post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryAnalysis AS (
    -- CTE to analyze post history and calculate the counts of different history types
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END) AS DeletedUndeletedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ph.PostId,
    ph.PostTitle,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.TotalVotes, 0) AS TotalVotes,
    COALESCE(h.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(h.DeletedUndeletedCount, 0) AS DeletedUndeletedCount,
    ph.Level,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS Answerers
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostVoteStats vs ON ph.PostId = vs.PostId
LEFT JOIN 
    PostHistoryAnalysis h ON ph.PostId = h.PostId
LEFT JOIN 
    Posts a ON ph.PostId = a.ParentId
LEFT JOIN 
    Users u ON a.OwnerUserId = u.Id
WHERE 
    ph.Level = 0 -- Only root questions
GROUP BY 
    ph.PostId, ph.PostTitle, vs.UpVotes, vs.DownVotes, vs.TotalVotes, h.CloseReopenCount, h.DeletedUndeletedCount, ph.Level
ORDER BY 
    ph.PostId;
