WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only select questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id
)

SELECT 
    u.DisplayName,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 END), 0) AS TotalQuestions,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 END), 0) AS TotalAnswers,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(CASE WHEN p.Score > 0 THEN p.Score END) AS AvgScoreOfAcceptedAnswers,
    MAX(p.ViewCount) AS MaxViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.ViewCount) DESC) AS Ranking
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'  -- String expression to find used tags
WHERE 
    u.Reputation IS NOT NULL  -- Avoid users with NULL reputation
GROUP BY 
    u.Id
HAVING 
    SUM(p.ViewCount) > 1000  -- Select only users whose posts have more than 1000 views
ORDER BY 
    Ranking, TotalQuestions DESC;

-- Additional analysis on accepted answers
SELECT 
    p.Id AS AcceptedAnswerId,
    p.Title AS AcceptedAnswer,
    u.DisplayName AS Owner,
    p.CreationDate,
    (
        SELECT COUNT(*)
        FROM Votes v
        WHERE v.PostId = p.Id
        AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    ) AS VoteCount,
    (SELECT STRING_AGG(Comment, ' | ') 
     FROM Comments c 
     WHERE c.PostId = p.Id) AS Comments
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 2 
    AND p.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE PostTypeId = 1)  -- Is an accepted answer
ORDER BY 
    VoteCount DESC, p.CreationDate DESC
LIMIT 5;  -- Limits the output to top 5 accepted answers
