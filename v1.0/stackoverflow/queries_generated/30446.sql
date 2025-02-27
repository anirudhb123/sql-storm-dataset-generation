WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON p.ParentId = a.Id
    WHERE 
        a.PostTypeId = 1
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes, -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes, -- Downvotes
        COUNT(DISTINCT b.Id) AS TotalBadges,
        MAX(p.CreationDate) AS MostRecentActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Filter by recent posts
    GROUP BY 
        p.Id, p.Title
),
PostHistoryFiltered AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        B.Name AS HistoryTypeName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes B ON ph.PostHistoryTypeId = B.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Only recent history
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.TotalComments,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.TotalBadges,
    ps.MostRecentActivity,
    ph.UserId AS LastEditorUserId,
    ph.HistoryTypeName AS LastEditType
FROM 
    PostStatistics ps
LEFT JOIN 
    PostHistoryFiltered ph ON ps.PostId = ph.PostId AND ph.rn = 1 -- Getting the last history entry
WHERE 
    ps.TotalComments > 0
ORDER BY 
    ps.TotalUpvotes DESC, ps.MostRecentActivity DESC
LIMIT 100;
