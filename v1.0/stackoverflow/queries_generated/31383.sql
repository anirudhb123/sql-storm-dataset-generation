WITH RecursivePostHierarchy AS (
    -- CTE to build a hierarchy of posts, capturing their relationships
    SELECT 
        Id, 
        Title, 
        ParentId, 
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostWithVotes AS (
    -- Calculating aggregated votes for each post
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 END), 0) AS OpenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
PostHistoryAggregated AS (
    -- Aggregating post history to analyze changes per post
    SELECT 
        ph.PostId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResult AS (
    SELECT 
        pwh.Id AS PostId,
        pwh.Title,
        pwh.UpVotes,
        pwh.DownVotes,
        pwh.CloseVotes,
        pwh.OpenVotes,
        COALESCE(pHA.ChangeCount, 0) AS TotalChanges,
        COALESCE(pHA.LastChangeDate, NULL) AS LastChangeDate,
        rph.Level AS PostLevel
    FROM 
        PostWithVotes pwh
    LEFT JOIN 
        PostHistoryAggregated pHA ON pwh.Id = pHA.PostId
    LEFT JOIN 
        RecursivePostHierarchy rph ON pwh.Id = rph.Id
)
SELECT 
    PostId,
    Title,
    UpVotes,
    DownVotes,
    CloseVotes,
    OpenVotes,
    TotalChanges,
    LastChangeDate,
    PostLevel
FROM 
    FinalResult
WHERE 
    UpVotes > DownVotes        -- Filter posts with more upvotes than downvotes
    AND (TotalChanges > 0 OR LastChangeDate IS NOT NULL)  -- Include posts with any recorded changes
ORDER BY 
    Score DESC,                -- Sort by score descending
    CreationDate ASC;          -- Then by creation date ascending
