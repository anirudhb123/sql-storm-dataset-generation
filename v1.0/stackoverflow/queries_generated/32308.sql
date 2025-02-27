WITH RecursivePostCTE AS (
    -- Recursive CTE to find all answers for questions, along with their ranks
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p.Id,
        pp.Title,
        pp.Score,
        pp.OwnerUserId,
        pp.AcceptedAnswerId,
        Level + 1,
        ROW_NUMBER() OVER (PARTITION BY pp.ParentId ORDER BY pp.Score DESC) AS rn
    FROM 
        Posts pp
    JOIN 
        RecursivePostCTE r ON r.PostId = pp.ParentId
)

SELECT 
    u.DisplayName,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
    SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE NULL END) AS AvgQuestionScore,
    AVG(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE NULL END) AS AvgAnswerScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    STRING_AGG(DISTINCT CONCAT(CAST(ph.CreationDate AS DATE), ' - ', ph.Comment), '; ') AS EditHistory,
    COALESCE(MAX(ph.CreationDate), 'Never Edited') AS LastEditDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalAnswerScore DESC, AvgQuestionScore DESC;

-- Additional query to find the most upvoted completed questions and their average answer scores
SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    q.Score AS QuestionScore,
    COUNT(a.Id) AS AnswerCount,
    AVG(a.Score) AS AvgAnswerScore
FROM 
    Posts q
LEFT JOIN 
    Posts a ON a.ParentId = q.Id AND a.PostTypeId = 2  -- Answers
WHERE 
    q.PostTypeId = 1 
    AND q.AcceptedAnswerId IS NOT NULL
GROUP BY 
    q.Id, q.Title, q.Score
HAVING 
    COUNT(a.Id) > 5
ORDER BY 
    QuestionScore DESC, AvgAnswerScore DESC
LIMIT 10;
