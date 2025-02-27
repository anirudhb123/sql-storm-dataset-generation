
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    ph.CreationDate AS HistoryCreationDate,
    p.Score AS PostScore,
    ph.Comment AS EditComment,
    p.ViewCount,
    p.AnswerCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, ph.CreationDate, p.Score, ph.Comment, p.ViewCount, p.AnswerCount
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;
