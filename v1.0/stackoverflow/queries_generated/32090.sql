WITH RecursiveCTE AS (
    -- This CTE will generate a list of posts along with their accepted answers.
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only include questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursiveCTE r ON p.Id = r.AcceptedAnswerId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(a.Score) AS TotalScore,
    AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(postHistory.CreationDate) AS LastEditedDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id -- Accepted answers
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Posts pLink ON pLink.Id IN (SELECT RelatedPostId FROM PostLinks WHERE PostId = p.Id) -- Links to other Posts
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN p.Tags) > 0 -- Tags related to the questions
LEFT JOIN 
    PostHistory postHistory ON postHistory.PostId = p.Id
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Only consider users with more than 5 questions
ORDER BY 
    TotalScore DESC;

-- This query gives a performance benchmark on notable users based on their questions, accepted answers, 
-- and contributions in badges, leveraging Cascading CTEs, Aggregations, and more to analyze the Posts, Users,
-- Badges, Tags and Post History, effectively demonstrating the relationships between them.
