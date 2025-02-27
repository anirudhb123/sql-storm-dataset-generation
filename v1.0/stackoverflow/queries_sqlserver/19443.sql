
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    C.Text AS CommentText,
    C.CreationDate AS CommentDate
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    C.Text, 
    C.CreationDate
ORDER BY 
    C.CreationDate DESC;
