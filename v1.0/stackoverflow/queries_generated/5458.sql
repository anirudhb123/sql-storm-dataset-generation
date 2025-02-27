SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pa.AnswerCount, 0) AS TotalAnswers,
    COALESCE(v UpVotes, 0) AS TotalUpVotes,
    COALESCE(v.DownVotes, 0) AS TotalDownVotes,
    p.Score,
    p.ViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS LastEditComment,
    ph.UserDisplayName AS LastEditorName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS TotalVotes,
    (SELECT Name FROM CloseReasonTypes crt JOIN PostHistory ph ON ph.Comment::int = crt.Id WHERE ph.PostHistoryTypeId = 10 AND ph.PostId = p.Id ORDER BY ph.CreationDate DESC LIMIT 1) AS CloseReason
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) pc ON p.Id = pc.PostId
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) pa ON p.Id = pa.ParentId
LEFT JOIN 
    (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId 
    AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    p.PostTypeId = 1 
AND 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, ph.CreationDate, ph.Comment, ph.UserDisplayName
ORDER BY 
    p.CreationDate DESC;
