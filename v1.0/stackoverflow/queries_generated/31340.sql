WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find the full hierarchy of posts (Questions and their Answers)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id as PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Joining with Answers (PostTypeId = 2)
), 

UserBadges AS (
    -- CTE to summarize user badge counts
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), 

PostVoteSummary AS (
    -- CTE to summarize votes on posts
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
) 

SELECT 
    up.DisplayName AS UserName,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(up.Views, 0) AS UserViews,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    rph.Title AS PostTitle,
    rph.PostId AS QuestionId,
    rph.Level AS HierarchyLevel,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Users up
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RecursivePostHierarchy rph ON up.Id = rph.OwnerUserId
LEFT JOIN 
    Comments c ON rph.PostId = c.PostId
LEFT JOIN 
    PostVoteSummary ps ON rph.PostId = ps.PostId
WHERE 
    up.Reputation > 1000  -- Filtering users with high reputation
    AND rph.Level <= 3   -- Limiting to a specific level in hierarchy
GROUP BY 
    up.DisplayName, ub.BadgeCount, up.Views, ps.UpVotes, ps.DownVotes, rph.Title, rph.PostId, rph.Level
ORDER BY 
    TotalUpVotes DESC, TotalBadges DESC
LIMIT 50;  -- Limiting the number of results for performance
