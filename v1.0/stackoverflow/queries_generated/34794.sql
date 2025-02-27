WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Starting from top-level posts
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        (COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) - COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END)) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoricalEvents,
        COUNT(DISTINCT ph.Id) AS EventCount
    FROM 
        PostHistory ph 
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ph.PostId,
    p.Title,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes,
    COALESCE(pga.HistoricalEvents, 'No History') AS HistoricalEvents,
    pga.EventCount AS HistoricalEventCount,
    rh.Level
FROM 
    RecursivePostHierarchy rh
LEFT JOIN 
    Posts p ON rh.PostId = p.Id
LEFT JOIN 
    PostVoteStats ps ON p.Id = ps.PostId
LEFT JOIN 
    PostHistoryAggregation pga ON p.Id = pga.PostId
WHERE 
    rh.Level <= 2 -- Limit the level of posts returned for performance benchmarking
ORDER BY 
    rh.Level, ps.NetVotes DESC
LIMIT 100;
