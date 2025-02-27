SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    pt.Name AS PostTypeName,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    (SELECT COUNT(*) FROM Posts AS sub_p WHERE sub_p.AcceptedAnswerId = p.Id) AS AcceptedAnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT 
         PostId, 
         unnest(string_to_array(Tags, '><')) AS TagName 
     FROM 
         Posts) AS t ON p.Id = t.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.Id, pt.Id
ORDER BY 
    PostCreationDate DESC
LIMIT 100;
