WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId  -- Join on Answers to Questions
)

SELECT 
    u.DisplayName AS User,
    r.PostId,
    r.Title AS PostTitle,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    COALESCE(MAX(b.Class), 0) AS HighestBadgeClass,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT ac.AuthorizedUserId) AS AuthorizedUsersCount
FROM 
    RecursivePostCTE r
INNER JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = r.PostId
LEFT JOIN 
    Votes v ON v.PostId = r.PostId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    (SELECT 
        b.UserId AS AuthorizedUserId
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(*) > 1) ac ON ac.AuthorizedUserId = u.Id
LEFT JOIN 
    LATERAL (SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName
    FROM 
        Posts p 
    WHERE 
        p.Id = r.PostId) t ON TRUE  -- Extract Tags from Posts
WHERE 
    r.Level = 1 -- Only top level (Questions)
GROUP BY 
    u.DisplayName, r.PostId, r.Title
ORDER BY 
    UpvoteCount DESC, CommentCount DESC;
