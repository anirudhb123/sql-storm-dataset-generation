WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Selecting only Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON ph.Id = p.ParentId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScores,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount,
    MAX(p.CreationDate) AS MostRecentPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    AVG(u.Views) AS AvgViews,
    COUNT(DISTINCT CASE 
        WHEN ph.Level > 0 THEN ph.Id END) AS NestedQuestionCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart or BountyClose
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT DISTINCT postId, unnest(string_to_array(Tags, ',')) as TagName FROM Posts) t ON p.Id = t.postId
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.Id
WHERE 
    u.Reputation > 1000 -- Consider only users with reputation greater than 1000
    AND p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
GROUP BY 
    u.Id
ORDER BY 
    TotalQuestions DESC, u.Reputation DESC
LIMIT 10;
