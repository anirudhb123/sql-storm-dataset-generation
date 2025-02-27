WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting with questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.OwnerUserId,
        p2.PostTypeId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN Posts p ON p2.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only link answers back to their questions
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(u.Reputation, 0) AS Reputation,
    COUNT(DISTINCT CASE WHEN ph.Level = 1 THEN ph.PostId END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN ph.Level > 1 THEN ph.PostId END) AS TotalAnswers,
    SUM(v.CreationDate IS NOT NULL) AS TotalVotesReceived, 
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    RecursivePostHierarchy ph ON u.Id = ph.OwnerUserId
LEFT JOIN 
    Votes v ON ph.PostId = v.PostId AND v.VoteTypeId IN (2, 3) -- Only considering upvotes and downvotes
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Comments c ON ph.PostId = c.PostId
LEFT JOIN 
    PostTypes pt ON ph.PostTypeId = pt.Id
WHERE 
    u.Reputation > 10 
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT ph.PostId) > 5
ORDER BY 
    TotalAnswers DESC, TotalQuestions DESC;
