WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Answers
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.Id = ph.ParentId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    p.Title,
    p.CreationDate AS PostCreationDate,
    ph.Level AS ResponseLevel,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpvoteCount, -- Assuming VoteTypeId '2' is for upvotes
    SUM(v.VoteTypeId = 3) AS DownvoteCount -- Assuming VoteTypeId '3' is for downvotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, b.BadgeCount, p.Title, p.CreationDate, ph.Level
ORDER BY 
    u.Reputation DESC, COUNT(DISTINCT c.Id) DESC, UpvoteCount DESC;
