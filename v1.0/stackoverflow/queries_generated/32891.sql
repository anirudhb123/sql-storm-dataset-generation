WITH RecursivePostCTE AS (
    -- CTE to recursively fetch all answers related to questions
    SELECT 
        p.Id AS PostId, 
        p.Title AS PostTitle, 
        p.Score, 
        p.CreationDate, 
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1

    UNION ALL

    SELECT 
        a.Id AS PostId, 
        a.Title AS PostTitle, 
        a.Score, 
        a.CreationDate, 
        a.OwnerUserId,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON r.PostId = a.ParentId
)

-- Main query to fetch user statistics along with answers and post history
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COUNT(DISTINCT p.PostId) AS QuestionCount,
    COUNT(DISTINCT CASE WHEN rp.Level > 0 THEN rp.PostId END) AS AnswerCount,
    SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
    AVG(CASE WHEN p.Score IS NOT NULL AND p.Score > 0 THEN p.Score ELSE NULL END) AS AverageScore,
    MAX(b.Date) AS LastBadgeDate,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    COUNT(DISTINCT ph.Id) AS HistoryActions,

    -- String concatenation of the most recent 5 edit descriptions
    (SELECT STRING_AGG(Description, '; ' ORDER BY CreationDate DESC) 
     FROM (SELECT ph.Comment AS Description 
           FROM PostHistory ph 
           WHERE ph.UserId = u.Id 
           ORDER BY ph.CreationDate DESC 
           LIMIT 5) AS RecentEdits) AS RecentEdits

FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecursivePostCTE rp ON p.Id = rp.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id

WHERE 
    u.Reputation > 100 -- condition to filter users with high reputation
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
HAVING 
    COUNT(DISTINCT p.Id) > 1 -- condition to ensure user has posted more than one question
ORDER BY 
    LastBadgeDate DESC NULLS LAST, TotalScore DESC;
