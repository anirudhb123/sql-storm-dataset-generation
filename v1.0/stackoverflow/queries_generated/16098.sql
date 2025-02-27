SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score, 
    P.ViewCount
FROM 
    Users AS U
JOIN 
    Posts AS P ON U.Id = P.OwnerUserId
WHERE 
    P.PostTypeId = 1 -- Filtering for Questions
ORDER BY 
    P.Score DESC
LIMIT 10; -- Get top 10 questions by score
