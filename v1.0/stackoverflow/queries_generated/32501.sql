WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.OwnerUserId,
        p2.CreationDate,
        COALESCE(p2.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON p2.ParentId = r.PostId
)
SELECT 
    Users.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalQuestionScore,
    SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    AVG(COALESCE(CASE WHEN p.CreationDate IS NOT NULL THEN DATEDIFF(day, p.CreationDate, GETDATE()) END, 0)) AS AvgQuestionAgeDays,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users
LEFT JOIN 
    Posts p ON p.OwnerUserId = Users.Id AND p.PostTypeId = 1  -- Questions
LEFT JOIN 
    Posts a ON a.ParentId = p.Id  -- Answers
LEFT JOIN 
    Badges b ON b.UserId = Users.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS t ON t = t.TagName
GROUP BY 
    Users.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- Filter users with more than 5 questions
ORDER BY 
    TotalQuestionScore DESC, TotalQuestions DESC;
