WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ParentId,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.Body,
        p2.ParentId,
        p2.OwnerUserId,
        p2.CreationDate,
        rp.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE rp ON rp.PostId = p2.ParentId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    pt.Name AS PostType,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    MAX(v.CreationDate) AS LastVoteDate,
    STRING_AGG(t.TagName, ', ') AS Tags,
    CASE 
        WHEN MAX(ph.CreationDate) IS NOT NULL THEN 'Edited' 
        ELSE 'Original' 
    END AS PostStatus
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate < NOW() -- Only edited posts
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2023-01-01 00:00:00' 
    AND p.Score > 0
GROUP BY 
    p.Id, p.Title, pt.Name
ORDER BY 
    UpVotes DESC, CommentCount DESC
LIMIT 50;

-- Recursive query yields a depth representation of questions and their answers, 
-- while the main query aggregates comment counts, vote totals, and badge counts for the post authors.
