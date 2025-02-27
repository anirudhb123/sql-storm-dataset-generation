
SELECT p.*, 
       (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id) AS VoteCount,
       (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount
FROM Posts p
WHERE CreationDate >= '2023-01-01'
GROUP BY p.Id, p.Title, p.Content, p.CreationDate, p.Author, p.Category, p.OtherColumns
ORDER BY CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
