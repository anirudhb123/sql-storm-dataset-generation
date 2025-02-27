WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starts with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.ParentId,
        ph.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(ph.Level) AS MaxAnswerDepth,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 0 AND 
    COUNT(DISTINCT v.Id) > 0
ORDER BY 
    TotalPosts DESC, TotalAnswers DESC
LIMIT 10;

-- Additional Aggregated Reporting
WITH VotesSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    p.Id,
    p.Title,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    (COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0)) AS NetVotes
FROM 
    Posts p
LEFT JOIN 
    VotesSummary vs ON p.Id = vs.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'
ORDER BY 
    NetVotes DESC
LIMIT 5;
