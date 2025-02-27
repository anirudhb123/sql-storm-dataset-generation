WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.ParentId = a.Id
    WHERE 
        a.PostTypeId = 1  -- Only Questions
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%' -- Assuming tags are stored in a way that allows a LIKE match
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
JOIN 
    (SELECT 
        PostId, COUNT(*) AS RelatedPostCount
     FROM 
        PostLinks
     GROUP BY 
        PostId
     HAVING 
        COUNT(*) > 1) AS RelatedPosts ON p.Id = RelatedPosts.PostId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 10 -- Users with more than 10 total posts
ORDER BY 
    TotalScore DESC;

WITH AllVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    av.VoteCount,
    av.UpVotes,
    av.DownVotes
FROM 
    RecursiveCTE r
LEFT JOIN 
    AllVotes av ON r.PostId = av.PostId
WHERE 
    r.Level = 1 -- Only top-level questions
ORDER BY 
    av.UpVotes DESC NULLS LAST;

SELECT 
    u.DisplayName,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(b.Name, ', ') AS Badges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    BadgeCount > 0
ORDER BY 
    BadgeCount DESC;
