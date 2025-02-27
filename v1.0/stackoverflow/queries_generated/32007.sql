WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        0 AS Level,
        CreationDate
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start from top-level posts (questions)

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1,  -- Increment level for child posts (answers)
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPost
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, u.DisplayName, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.Id,
    ps.Title,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(cp.LastClosedDate, 'Not Closed') AS LastClosedDate,
    r.Level AS PostLevel
FROM 
    PostSummary ps
LEFT JOIN 
    ClosedPosts cp ON ps.Id = cp.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON ps.Id = r.Id
WHERE 
    ps.RankPost <= 5  -- Consider only the latest 5 posts per user
ORDER BY 
    ps.ViewCount DESC, ps.CommentCount DESC, ps.UpVotes DESC;

