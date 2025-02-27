WITH RecursivePostCTE AS (
    -- Recursive CTE to gather Post information based on accepted answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only start with Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.Score,
        p2.ViewCount,
        p2.CreationDate,
        p2.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON r.PostId = p2.ParentId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT p2.Id) AS TotalAnswers,
    SUM(COALESCE(vs.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(vs.DownVotes, 0)) AS TotalDownVotes,
    SUM(CASE 
            WHEN b.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    MAX(vs.CreationDate) AS LastVoteDate 
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts p2 ON p.Id = p2.AcceptedAnswerId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- UpVotes
LEFT JOIN 
    (SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
     FROM 
        Votes 
     GROUP BY 
        PostId) vs ON p.Id = vs.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT 
        p.Id, 
        STRING_AGG(t.TagName, ', ') AS TagName 
     FROM 
        Posts p 
     CROSS JOIN 
        Tags t 
     WHERE 
         p.Tags LIKE '%' || t.TagName || '%' 
     GROUP BY 
        p.Id) t ON p.Id = t.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;
