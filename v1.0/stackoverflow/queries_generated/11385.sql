-- Performance benchmark query to analyze post activity and user engagement
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS Author,
    u.Reputation AS AuthorReputation,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    t.TagName AS Tags,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Consider posts created in the last year
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit results for benchmarking purposes
