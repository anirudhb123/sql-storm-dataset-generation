WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        a.CreationDate,
        a.OwnerUserId,
        a.PostTypeId,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePosts r ON a.ParentId = r.PostId  -- Getting Answers for each Question
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    COUNT(DISTINCT CASE 
        WHEN rp.PostTypeId = 1 THEN rp.PostId 
        END) AS TotalQuestions,
    COUNT(DISTINCT CASE 
        WHEN rp.PostTypeId = 2 THEN rp.PostId 
        END) AS TotalAnswers,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    MAX(rp.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
FROM 
    RecursivePosts rp
INNER JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(COALESCE(p.Tags, ''), ',') AS tagArray ON TRUE  -- Getting Tags from Posts
LEFT JOIN 
    Tags t ON t.TagName = tagArray[]
WHERE 
    u.Reputation > 1000  -- Filtering for users with reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5  -- Only include users with more than 5 posts
ORDER BY 
    TotalScore DESC, TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;  -- Limit to top 10 users
