WITH RecursivePosts AS (
    -- Recursive CTE to find all posts and their accepted answers
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        0 AS Level,
        p.AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Considering only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        Level + 1 AS Level,
        p.AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        RecursivePosts rp ON rp.AcceptedAnswerId = p.Id
)

-- Main query to retrieve detailed statistics
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN rp.AcceptedAnswerId IS NOT NULL THEN rp.Id END) AS AcceptedAnswers,
    AVG(u.Views) AS AverageViews,
    SUM(COALESCE(b.Class, 0)) AS TotalBadgePoints,
    STRING_AGG(DISTINCT ph.Comment, ', ') AS RecentChanges,
    MAX(ph.CreationDate) AS LastPostEdit
FROM 
    Users u
LEFT JOIN 
    RecursivePosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId
LEFT JOIN 
    Votes v ON rp.Id = v.PostId
WHERE 
    u.Reputation > 1000  -- User with reputation greater than 1000
    AND EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id 
        AND p.PostTypeId = 1 
        AND p.Score > 5 -- Having questions with score greater than 5
    )
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalQuestions DESC, AverageViews DESC
FETCH FIRST 10 ROWS ONLY;

-- The query will provide detailed statistics about users who have a good reputation
