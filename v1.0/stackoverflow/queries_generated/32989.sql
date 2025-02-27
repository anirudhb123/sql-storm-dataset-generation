WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        a.Score,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    WHERE 
        q.PostTypeId = 1  -- Keep fetching answers to questions
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT r.PostId) AS TotalPosts,
    SUM(r.Score) AS TotalScore,
    COALESCE(MAX(b.Date), '1900-01-01') AS LastBadgeDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,  -- Count only UpVotes
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes   -- Count only DownVotes    
FROM 
    Users u
LEFT JOIN 
    RecursiveCTE r ON u.Id = r.OwnerUserId
LEFT JOIN 
    Tags t ON r.Tags::text ILIKE '%' || t.TagName || '%'
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT r.PostId) > 10  -- Only users with more than 10 posts
ORDER BY 
    TotalScore DESC,
    TotalPosts DESC;

-- Additional segment to show recursive depth and note on data integrity
WITH PostHierarchy AS (
    SELECT 
        p.Id,
        COALESCE(c.UserDisplayName, 'Community') AS OwnerDisplayName,
        r.Level,
        p.Title
    FROM 
        Posts p
    LEFT JOIN 
        Users c ON p.OwnerUserId = c.Id
    JOIN 
        RecursiveCTE r ON p.Id = r.PostId
)
SELECT 
    Level,
    COUNT(*) AS PostCount,
    MIN(Title) AS SamplePostTitle
FROM 
    PostHierarchy
GROUP BY 
    Level
ORDER BY 
    Level;
