WITH RecursivePostHistory AS (
    -- CTE to create a recursive structure to show the history of posts, including parents
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.UserId, 
        ph.Comment,
        ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closing and Reopening posts
    UNION ALL
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.UserId, 
        ph.Comment,
        ph.PostHistoryTypeId,
        rh.Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rh ON ph.PostId = rh.PostId
    WHERE 
        ph.CreationDate < rh.CreationDate
),
PostScoreSummary AS (
    -- CTE to summarize post scores
    SELECT 
        p.Id AS PostId,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(v.Id) AS TotalVotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserBadgeSummary AS (
    -- CTE to summarize users and their highest badge class
    SELECT 
        u.Id AS UserId,
        MAX(b.Class) AS HighestBadgeClass,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    ps.TotalVotes,
    ps.TotalBounty,
    ps.AverageBounty,
    u.DisplayName AS OwnerName,
    ub.TotalBadges,
    ub.HighestBadgeClass,
    CAST(ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS INT) AS ActivityRank,
    COALESCE(rp.UserId, 'No Action') AS LastActionByUserId,
    COUNT(c.Id) AS CommentsCount
FROM 
    Posts p
JOIN 
    PostScoreSummary ps ON p.Id = ps.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeSummary ub ON ub.UserId = u.Id
LEFT JOIN 
    RecursivePostHistory rp ON p.Id = rp.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '90 days'
    AND (p.ViewCount > 100 OR ps.TotalVotes > 5) -- Complex predicates
GROUP BY 
    p.Id, ps.TotalVotes, ps.TotalBounty, ps.AverageBounty, u.DisplayName, ub.TotalBadges, ub.HighestBadgeClass, rp.UserId
HAVING 
    COUNT(c.Id) > 0 -- Only show posts with comments
ORDER BY 
    ps.TotalVotes DESC, ActivityRank;
