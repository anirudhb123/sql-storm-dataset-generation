WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions as the root

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
        Posts q ON a.ParentId = q.Id
    WHERE 
        q.PostTypeId = 1
)
SELECT 
    u.DisplayName AS User,
    COUNT(DISTINCT p.Id) AS QuestionsCount,
    COUNT(DISTINCT a.Id) AS AnswersCount,
    SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
    AVG(COALESCE(a.Score, 0)) AS AvgAnswerScore,
    COALESCE(p.ClosedDate, 'N/A') AS ClosedDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(ps.LastEditDate) AS LastEdited,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT a.Id) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1  -- Questions
LEFT JOIN 
    Posts a ON a.ParentId = p.Id  -- Answers related to Questions
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id OR pl.RelatedPostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId  -- Assuming related posts are tagged
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.PostId = p.Id
LEFT JOIN 
    Posts ps ON ps.Id = rph.AcceptedAnswerId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 0  -- Only include users with questions
ORDER BY 
    Rank, TotalAnswerScore DESC;
