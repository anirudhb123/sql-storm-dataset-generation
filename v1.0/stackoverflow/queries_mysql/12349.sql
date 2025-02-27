
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) AS HistoryCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL 30 DAY 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName, u.Reputation, 
    p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
