WITH RecursivePostHierarchy AS (
    -- CTE to get the post hierarchy for questions and their answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
    WHERE 
        p2.PostTypeId = 2  -- Answers only
)
, PostEngagement AS (
    -- Aggregate user engagement metrics at post level
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
)
, RecentUsersWithBadges AS (
    -- CTE to fetch users with badges created recently
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= NOW() - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.QuestionId AS PostId,
    r.Title AS QuestionTitle,
    pe.TotalUpvotes,
    pe.TotalDownvotes,
    pe.CommentCount,
    u.UserId,
    u.DisplayName AS BadgeOwner,
    ub.BadgeCount,
    ROW_NUMBER() OVER (PARTITION BY r.QuestionId ORDER BY r.Level DESC) AS AnswerLevel
FROM 
    RecursivePostHierarchy r
JOIN 
    PostEngagement pe ON r.PostId = pe.PostId
LEFT JOIN 
    RecentUsersWithBadges ub ON r.PostId = ub.UserId
WHERE 
    pe.TotalUpvotes - pe.TotalDownvotes > 0  -- Filtering for positively engaging questions
ORDER BY 
    pe.TotalUpvotes DESC, AnswerLevel;
