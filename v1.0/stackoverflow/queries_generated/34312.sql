WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting from questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        a.OwnerUserId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON a.ParentId = r.PostId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT r.PostId) AS AnswerCount,
    AVG(r.ViewCount) AS AvgViews,
    SUM(r.Score) AS TotalScore,
    MAX(r.CreationDate) AS MostRecentActivity
FROM 
    Users u
LEFT JOIN 
    RecursivePostCTE r ON u.Id = r.OwnerUserId
WHERE 
    u.Reputation > 100 -- users with reputation more than 100
    AND r.Level = 1 -- Only include questions
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT r.PostId) > 0
ORDER BY 
    TotalScore DESC, AvgViews DESC
LIMIT 10;

-- This query retrieves the top 10 users with more than 100 reputation who have asked questions
-- It calculates the number of answers, average views of their questions, total score of their questions,
-- and the most recent activity date of their questions, ordering by total score first, then by average views.
