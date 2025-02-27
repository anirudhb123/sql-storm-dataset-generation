SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    (SELECT COALESCE(AVG(Score), 0) 
     FROM Posts p2 WHERE p2.AcceptedAnswerId = p.Id) AS AvgAcceptedAnswerScore,
    p.LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON tagName IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tagName
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
