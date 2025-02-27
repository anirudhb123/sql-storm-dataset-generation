
SELECT p.*, 
       (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id) AS VoteCount, 
       (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount 
FROM Posts p 
WHERE CreationDate >= '2023-01-01' 
GROUP BY p.Id, p.CreationDate, p.Title, p.Content, p.AuthorId, p.SomeOtherColumn -- Add all necessary columns here 
ORDER BY CreationDate DESC 
LIMIT 10;
