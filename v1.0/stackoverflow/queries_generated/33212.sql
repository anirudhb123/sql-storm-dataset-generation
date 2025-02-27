WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p 
    JOIN 
        Posts a ON p.ParentId = a.Id
    JOIN 
        RecursivePostHierarchy r ON a.AcceptedAnswerId = r.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT p2.Id) AS AcceptedAnswers,
    SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotes,
    AVG(COALESCE(vs.VoteCount, 0)) AS AverageVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(ph.CreationDate) AS LatestPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts p2 ON p.Id = p2.AcceptedAnswerId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod votes
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS VoteCount 
     FROM 
        Votes 
     GROUP BY 
        PostId) vs ON p.Id = vs.PostId
LEFT JOIN 
    STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t ON true  -- Extracting tags
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Closed and reopened
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalPosts DESC, AverageVotes DESC
LIMIT 100;

SELECT 
    a.UserName,
    a.VoteCount,
    b.CommentCount
FROM 
    (SELECT 
        u.DisplayName AS UserName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteCount
     FROM 
        Users u
     JOIN 
        Votes v ON u.Id = v.UserId
     GROUP BY 
        u.DisplayName) a
FULL OUTER JOIN 
    (SELECT 
        u.DisplayName AS UserName,
        COUNT(c.Id) AS CommentCount
     FROM 
        Users u
     JOIN 
        Comments c ON u.Id = c.UserId
     GROUP BY 
        u.DisplayName) b ON a.UserName = b.UserName
WHERE 
    COALESCE(a.VoteCount, 0) > 5 OR COALESCE(b.CommentCount, 0) > 10
ORDER BY 
    COALESCE(a.VoteCount, 0) DESC, COALESCE(b.CommentCount, 0) DESC;

