WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(MAX(b.Class), 0) AS HighestBadge
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS ChangeComments,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.Id,
    ps.Title,
    ps.CreationDate,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.CommentCount,
    COALESCE(pdh.ChangeComments, 'No changes') AS ChangeComments,
    COALESCE(pdh.ChangeCount, 0) AS ChangeCount,
    rph.Level AS HierarchyLevel
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryDetails pdh ON ps.Id = pdh.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON ps.Id = rph.PostId
WHERE 
    ps.UpvoteCount > ps.DownvoteCount
ORDER BY 
    ps.UpvoteCount DESC, 
    ps.CommentCount DESC;
