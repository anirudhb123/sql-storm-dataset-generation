-- Performance Benchmarking Query for StackOverflow Schema

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    U.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    AVG(b.Reputation) AS AverageUserReputation,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenVotes
FROM 
    Posts p
JOIN 
    Users U ON p.OwnerUserId = U.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate BETWEEN '2022-01-01' AND '2023-01-01' -- Filtering based on the creation date
GROUP BY 
    p.Id, U.DisplayName
ORDER BY 
    p.CreationDate DESC;
