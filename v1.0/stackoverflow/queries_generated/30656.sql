WITH RecursivePostHierarchy AS (
    -- CTE to establish a hierarchy of posts and their accepted answers
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.OwnerUserId, 
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Score, 
        p.OwnerUserId, 
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS Owner,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    SUM(CASE WHEN COALESCE(a.Score, 0) > 0 THEN a.Score ELSE 0 END) AS PositiveAnswerScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(p.CreationDate) AS MostRecentActivity
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers

-- Join with Tags using a string split on the Tags field from Posts
LEFT JOIN 
    LATERAL (
        SELECT 
            DISTINCT t.TagName 
        FROM 
            Tags t 
        WHERE 
            t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    ) t ON true

GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Only include users with more than 5 questions
ORDER BY 
    TotalQuestions DESC, 
    PositiveAnswerScore DESC;

-- This query combines various constructs:
-- - Recursive CTE to build a hierarchy of questions and answers
-- - LEFT JOINs to combine user data with posts
-- - STRING_AGG to gather tags used across all questions
-- - Complex HAVING for filtering the results based on a calculated aggregate
-- - NULL handling with COALESCE to avoid score issues.
