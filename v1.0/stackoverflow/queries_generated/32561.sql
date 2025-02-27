WITH RecursivePostHierarchy AS (
    -- CTE to build a recursive structure of questions and answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        0 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        r.Level + 1,
        p.CreationDate
    FROM 
        RecursivePostHierarchy r
    JOIN 
        Posts p ON r.PostId = p.ParentId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS QuestionsAsked,
    COUNT(DISTINCT a.PostId) AS AnswersGiven,
    SUM(p.ViewCount) AS TotalQuestionViews,
    AVG(DATEDIFF(CURRENT_TIMESTAMP, p.CreationDate)) AS AvgDaysToAnswer,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    CASE 
        WHEN COUNT(b.Id) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    MAX(v.CreationDate) AS LastActivityDate,
    LEAD(MAX(v.CreationDate)) OVER (PARTITION BY u.Id ORDER BY MAX(v.CreationDate) DESC) AS PreviousActivityDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON a.OwnerUserId = u.Id AND a.PostTypeId = 2 -- Answers
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%') -- Assuming tags stored as string
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Votes v ON v.UserId = u.Id
LEFT JOIN 
    RecursivePostHierarchy r ON r.PostId = a.ParentId
WHERE 
    u.Reputation > 1000 -- Include users with reputation above 1000
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    SUM(p.ViewCount) > 1000 -- Only consider users whose questions have been viewed more than 1000 times
ORDER BY 
    QuestionsAsked DESC, AnswersGiven DESC;
