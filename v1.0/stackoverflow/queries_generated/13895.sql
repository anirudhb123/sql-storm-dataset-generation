-- Performance benchmarking query to analyze posts and their associated metadata
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
