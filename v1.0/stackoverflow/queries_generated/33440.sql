WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
)
SELECT 
    u.DisplayName AS Author,
    p.Title AS QuestionTitle,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    MAX(v.CreationDate) AS LastVoteDate,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    MAX(CASE 
        WHEN ph1.PostHistoryTypeId = 10 THEN 'Closed' 
        WHEN ph1.PostHistoryTypeId IN (10, 11) THEN 'Status Changed' 
        ELSE 'Active' 
    END) AS Status,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT pl.RelatedPostId) AS TotalLinks,
    ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY r.Level DESC) AS PostLevel 
FROM 
    RecursivePostHierarchy r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph1 ON p.Id = ph1.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON t.WikiPostId = p.Id
WHERE 
    r.Level < 3 
GROUP BY 
    u.DisplayName, p.Title
HAVING 
    COUNT(DISTINCT c.Id) > 5 AND 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10 -- More than 10 UpVotes
ORDER BY 
    TotalAnswers DESC, 
    TotalComments DESC;
