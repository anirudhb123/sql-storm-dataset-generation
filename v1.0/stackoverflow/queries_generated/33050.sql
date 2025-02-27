WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        1 AS Level
    FROM 
        Posts p
    JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.AcceptedAnswerId

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        Tags || DISTINCT t.TagName,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostCTE r ON r.AcceptedAnswerId = p.Id
    JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.PostTypeId = 2 -- Only Answers
)
SELECT 
    u.DisplayName,
    r.Id AS PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM 
    RecursivePostCTE r
LEFT JOIN 
    Users u ON u.Id = r.OwnerUserId
LEFT JOIN 
    Comments c ON c.PostId = r.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    UNNEST(r.Tags) AS t(TagName)
WHERE 
    r.Score > 0
GROUP BY 
    u.DisplayName, r.Id, r.Title, r.CreationDate, r.Score, r.ViewCount
HAVING 
    COUNT(DISTINCT b.Id) > 0
ORDER BY 
    r.ViewCount DESC, r.Score DESC
LIMIT 100;


This query utilizes a recursive common table expression (CTE) to gather all related questions and answers, aggregates tags, and fetches user information along with badge counts and comment counts. The final selection filters by post score and groups by user, displaying a comprehensive view of top posts while sorting them based on view count and score.
