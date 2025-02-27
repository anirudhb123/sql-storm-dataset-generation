WITH RecursivePostHierarchy AS (
    -- Recursive CTE to gather parent-child relationships for posts
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts AS p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts AS p
    INNER JOIN 
        RecursivePostHierarchy AS rph 
    ON 
        p.ParentId = rph.PostId
),
UserBadges AS (
    -- CTE to gather user badges and their most recent acquisition date
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS MostRecentBadgeDate
    FROM 
        Badges AS b
    GROUP BY 
        b.UserId
),
PostVoteSummary AS (
    -- Summarizing post votes, calculating the net score, and counting vote types
    SELECT 
        p.Id,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetScore,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts AS p
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(rph.Level, -1) AS HierarchyLevel,  -- -1 if the post has no parent
    u.DisplayName AS OwnerName,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.MostRecentBadgeDate, 'No badges') AS UserMostRecentBadgeDate,
    pvs.NetScore,
    pvs.TotalVotes
FROM 
    Posts AS p
INNER JOIN 
    Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecursivePostHierarchy AS rph ON p.Id = rph.PostId
LEFT JOIN 
    UserBadges AS ub ON u.Id = ub.UserId
LEFT JOIN 
    PostVoteSummary AS pvs ON p.Id = pvs.Id
WHERE 
    p.Score > 0  -- Only considering posts that have a positive score
    AND (p.Tags LIKE '%sql%' OR p.Tags LIKE '%database%')  -- Looking for SQL-related posts
    AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Posts from the last year
ORDER BY 
    pvs.NetScore DESC, 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;  -- Pagination
