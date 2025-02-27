WITH RecursivePostHierarchy AS (
    -- Base case: Select all top-level questions (PostTypeId = 1)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1

    UNION ALL

    -- Recursive case: Join to find answers to questions
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        ph.Level + 1
    FROM 
        Posts a
    JOIN 
        RecursivePostHierarchy ph ON a.ParentId = ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.Level = 0 THEN 1 END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.Level > 0 THEN 1 END) AS TotalAnswers,
    SUM(v.BountyAmount) AS TotalBounty,
    AVG(CASE WHEN v.UserId IS NOT NULL THEN v.BountyAmount ELSE 0 END) AS AvgBounty,
    MAX(p.CreationDate) AS LastActivityDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    RecursivePostHierarchy p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId AND v.VoteTypeId = 8  -- Bounty Start Votes
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, ',')) AS TagName
        FROM 
            Posts p2
        WHERE 
            p2.Id = p.PostId
    ) AS t ON TRUE
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.PostId) > 5  -- Filter for users with more than 5 posts
ORDER BY 
    TotalPosts DESC, LastActivityDate DESC;
