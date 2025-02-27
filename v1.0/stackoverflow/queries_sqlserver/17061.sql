
SELECT u.DisplayName, p.Title, p.CreationDate, v.VoteTypeId
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
JOIN Votes v ON p.Id = v.PostId
WHERE v.VoteTypeId = 2 
GROUP BY u.DisplayName, p.Title, p.CreationDate, v.VoteTypeId
ORDER BY p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
