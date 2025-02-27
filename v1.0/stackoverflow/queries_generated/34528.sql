WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with top-level questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.CreationDate,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostScores AS (
    SELECT 
        p.Id,
        p.Score + COALESCE(uv.UpVotes, 0) - COALESCE(uv.DownVotes, 0) AS AdjustedScore
    FROM 
        Posts p
    LEFT JOIN 
        UserVoteCounts uv ON p.OwnerUserId = uv.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.CreationDate,
    rph.Level,
    ps.AdjustedScore,
    cp.CreationDate AS ClosedDate,
    cp.Comment AS ClosureReason,
    cp.UserDisplayName AS ClosedBy
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    PostScores ps ON rph.PostId = ps.Id
LEFT JOIN 
    ClosedPosts cp ON rph.PostId = cp.PostId
WHERE 
    ps.AdjustedScore > 10
ORDER BY 
    rph.Level, ps.AdjustedScore DESC;

