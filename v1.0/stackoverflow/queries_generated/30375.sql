WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.Body,
        a.Score,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursiveCTE r ON q.Id = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers
)
SELECT 
    u.DisplayName AS Author,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Body,
    r.Score,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 3) AS DownVotes,
    CASE 
        WHEN r.Level = 1 THEN 'Question'
        ELSE 'Answer'
    END AS PostType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY r.PostId ORDER BY r.Score DESC) AS Rank
FROM 
    RecursiveCTE r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON c.PostId = r.PostId
LEFT JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag(tagName) ON true
LEFT JOIN 
    Tags t ON t.TagName = tag.tagName
WHERE 
    r.PostId IS NOT NULL 
GROUP BY 
    u.DisplayName, 
    r.PostId, 
    r.Title, 
    r.CreationDate, 
    r.Body, 
    r.Score, 
    r.Level
ORDER BY 
    Rank, 
    CommentCount DESC;
