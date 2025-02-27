WITH RecursivePosts AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        1 AS Level
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
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostWithHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Id AS HistoryId,
        ph.CreationDate AS HistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    rp.Title AS PostTitle,
    rp.Level AS PostLevel,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN pvs.TotalVotes IS NULL THEN 0 
        ELSE pvs.TotalVotes 
    END AS TotalVotes,
    ph.HistoryId AS LastHistoryId,
    ph.HistoryDate AS LastHistoryDate,
    CASE 
        WHEN ph.HistoryId IS NULL THEN 'No history available'
        ELSE 'History available'
    END AS HistoryStatus
FROM 
    RecursivePosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    PostWithHistory ph ON rp.Id = ph.PostId
WHERE 
    rp.Level <= 2 
ORDER BY 
    rp.CreationDate DESC;
