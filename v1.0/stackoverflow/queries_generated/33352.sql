WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
)

, UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(v.BountyAmount) AS AvgBounty,  -- Average Bounty on answers
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

, PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    p.Id,
    p.Title,
    COALESCE(r.Level, 0) AS HierarchyLevel,
    u.DisplayName AS Owner,
    ps.TotalQuestions,
    ps.TotalAnswers,
    t.TagName AS PopularTag,
    ps.AvgBounty,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id
LEFT JOIN 
    UserPostStats ps ON p.OwnerUserId = ps.UserId
LEFT JOIN 
    PopularTags t ON t.TagName = ANY(string_to_array(p.Tags, '>'))
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'  -- Recent posts
AND 
    (p.Title ILIKE '%help%' OR p.Body ILIKE '%help%')  -- If title or body contains 'help'
GROUP BY 
    p.Id, ps.UserId, t.TagName
HAVING 
    SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END) > 5  -- Having more than 5 comments
ORDER BY 
    SUM(p.Score) DESC,  -- Order by total score of posts descending
    ps.TotalPosts DESC;  -- then by total posts
