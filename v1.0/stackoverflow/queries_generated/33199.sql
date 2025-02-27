WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        CAST(1 AS INT) AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        p2.CreationDate,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    SUM(v.Score) AS TotalVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags,
    MAX(last_activity.LastActivityDate) AS RecentActivity,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions
LEFT JOIN 
    Posts a ON a.ParentId = p.Id  -- Answers to those questions
LEFT JOIN 
    Votes v ON v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, ', ')))  -- Assuming tags are comma-separated
LEFT JOIN 
    (SELECT 
        p3.Id, 
        p3.LastActivityDate 
     FROM 
        Posts p3 
     WHERE 
        p3.PostTypeId IN (1, 2)) last_activity ON last_activity.Id = p.Id
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    SUM(v.Score) > 0  -- Users must have at least one vote
ORDER BY 
    TotalQuestions DESC, TotalVotes DESC;
