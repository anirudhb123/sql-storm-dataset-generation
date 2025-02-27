WITH RecursiveCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        rc.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE rc ON p.ParentId = rc.Id
    WHERE 
        p.PostTypeId = 2 -- Get answers to questions
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate AS PostCreationDate,
    ph.LastClosedDate,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    ph.CloseOpenCount,
    rc.Level AS AnswerLevel,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount 
FROM 
    Posts p
LEFT JOIN 
    PostVoteStats vs ON p.Id = vs.PostId
LEFT JOIN 
    PostHistoryStats ph ON p.Id = ph.PostId
LEFT JOIN 
    RecursiveCTE rc ON p.Id = rc.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    p.Score DESC,
    TotalUpVotes DESC
LIMIT 100;
