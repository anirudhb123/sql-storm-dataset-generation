WITH RecursivePostCTE AS (
    SELECT 
        Id,
        PostTypeId,
        ParentId,
        Title,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Starting point: root posts (questions)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.PostTypeId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id -- Recursive join to find answers
), 
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering posts from the last year
    GROUP BY 
        p.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    r.Id AS PostId,
    r.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(vs.UpVotes, 0) AS UpVoteCount,
    COALESCE(vs.DownVotes, 0) AS DownVoteCount,
    ph.ClosedDate,
    ph.ReopenedDate,
    ROW_NUMBER() OVER (PARTITION BY r.PostId ORDER BY r.CreationDate DESC) AS RowNum
FROM 
    RecursivePostCTE r
LEFT JOIN 
    Comments c ON r.Id = c.PostId
LEFT JOIN 
    PostVoteStats vs ON r.Id = vs.PostId
LEFT JOIN 
    PostHistoryAggregates ph ON r.Id = ph.PostId
GROUP BY 
    r.Id, r.Title, vs.UpVotes, vs.DownVotes, ph.ClosedDate, ph.ReopenedDate
HAVING 
    COUNT(DISTINCT c.Id) > 3 -- Filter for posts with more than 3 comments
ORDER BY 
    r.CreationDate DESC
LIMIT 100; -- Limit results for performance benchmarking
