WITH RecursivePostHistory AS (
    -- Recursive CTE to get the edit history of each post
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditVersion
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (2, 4, 6) -- Initial Body, Edit Title, Edit Tags
),
RecentUserActivity AS (
    -- CTE to grab recent user activities and their gained badges
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= NOW() - INTERVAL '30 days' -- Badge awarded within the last 30 days
),
PostStatistics AS (
    -- CTE to summarize post stats including the number of comments and average score
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        AVG(v.VoteTypeId = 2) AS AvgUpvotes, -- Assuming 2 is UpMod
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes -- Assuming 3 is DownMod
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    ps.TotalComments,
    ps.AvgUpvotes,
    ps.TotalDownvotes,
    MAX(rph.EditDate) AS LastEditDate,
    ru.DisplayName AS RecentUser,
    ru.BadgeName AS RecentBadge
FROM 
    Posts p
LEFT JOIN 
    PostStatistics ps ON p.Id = ps.PostId
LEFT JOIN 
    RecursivePostHistory rph ON p.Id = rph.PostId
LEFT JOIN 
    (SELECT * FROM RecentUserActivity WHERE BadgeRank = 1) ru ON ru.UserId = p.OwnerUserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    AND (ps.TotalComments > 0 OR ps.AvgUpvotes > 5) -- Posts with comments or positive engagement
    AND p.ClosedDate IS NULL -- Only open posts
GROUP BY 
    p.Id, ps.TotalComments, ru.DisplayName, ru.BadgeName
ORDER BY 
    p.ViewCount DESC, LastEditDate DESC; -- Order by popularity and recent activity
