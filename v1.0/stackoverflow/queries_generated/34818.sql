WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get all answers for questions
    SELECT 
        Id AS PostId, 
        ParentId,
        0 AS Level,
        Title
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        Level + 1,
        p.Title
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers
),
PostWithStats AS (
    -- Aggregate stats related to questions and their direct answers
    SELECT 
        q.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(a.Score), 0) AS TotalAnswerScore,
        MAX(a.CreationDate) AS LatestAnswerDate
    FROM 
        Posts q
    LEFT JOIN 
        Posts a ON q.Id = a.ParentId AND a.PostTypeId = 2 -- Join to get answers
    WHERE 
        q.PostTypeId = 1  -- We only want questions
    GROUP BY 
        q.Id
),
UserBadges AS (
    -- Retrieve users and their earned badges
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentActivity AS (
    -- Check for recent activity in posts (last activity within the last 30 days)
    SELECT 
        p.Id AS PostId,
        CASE 
            WHEN p.LastActivityDate >= NOW() - INTERVAL '30 days' THEN 1 
            ELSE 0 
        END AS RecentlyActive
    FROM 
        Posts p
)
SELECT 
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    ph.QuestionId,
    ph.AnswerCount,
    ph.TotalAnswerScore,
    ra.RecentlyActive,
    COALESCE(ra.RecentlyActive, 0) AS IsRecentActivity
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostWithStats ph ON u.Id = ph.QuestionId
LEFT JOIN 
    RecentActivity ra ON ph.QuestionId = ra.PostId
WHERE 
    ub.BadgeCount > 0 
    OR ph.AnswerCount > 0
ORDER BY 
    u.Reputation DESC,
    ph.TotalAnswerScore DESC,
    ph.LatestAnswerDate DESC;
