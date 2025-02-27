WITH RecursivePostHierarchy AS (
    -- Recursive CTE to gather all answers for questions including their hierarchy
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Initial questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy rp ON a.ParentId = rp.PostId
)

, UserReputation AS (
    -- CTE to summarize user reputations and their associated badges
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass  -- Find highest badge class
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title AS QuestionTitle,
    u.Reputation AS UserReputation,
    ur.BadgeCount AS TotalBadges,
    ur.HighestBadgeClass,
    (SELECT COUNT(*) FROM Posts sub WHERE sub.ParentId = rp.PostId AND sub.PostTypeId = 2) AS AnswerCount,
    ARRAY_AGG(DISTINCT c.Text) FILTER (WHERE c.Text IS NOT NULL) AS CommentTexts, -- Aggregate comments
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists' 
        ELSE 'No Accepted Answer' 
    END AS AcceptanceStatus
FROM 
    RecursivePostHierarchy rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
GROUP BY 
    rp.PostId, rp.Title, u.Reputation, ur.BadgeCount, ur.HighestBadgeClass, rp.AcceptedAnswerId
ORDER BY 
    UserReputation DESC, TotalBadges DESC;
