WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of posts (questions and their answers)
    SELECT 
        Id,
        ParentId,
        1 AS Level,
        CAST(Title AS VARCHAR(MAX)) AS TitlePath
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Only start from Questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        Level + 1,
        CAST(r.TitlePath + ' -> ' + p.Title AS VARCHAR(MAX))
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteStats AS (
    -- Query to compute vote statistics for posts
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId IN (2, 4) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 10 THEN 1 END) AS Deletions
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostEditingHistory AS (
    -- Analyze edits for tracking if they resulted in post closure or deletion
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10) THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12) THEN ph.CreationDate END) AS DeleteDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.OwnerDisplayName,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(pe.EditCount, 0) AS EditCount,
    pe.IsClosed,
    pe.CloseDate,
    pe.DeleteDate,
    rh.TitlePath AS PostHierarchy
FROM 
    Posts p
LEFT JOIN 
    PostVoteStats ps ON p.Id = ps.PostId
LEFT JOIN 
    PostEditingHistory pe ON p.Id = pe.PostId
LEFT JOIN 
    RecursivePostHierarchy rh ON p.ParentId = rh.Id
WHERE 
    p.PostTypeId = 1  -- Only interested in questions
    AND (ps.UpVotes > 10 OR ps.DownVotes < 5)  -- Filtering based on votes
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
