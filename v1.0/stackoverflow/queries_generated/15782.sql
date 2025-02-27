SELECT 
    U.DisplayName AS UserName, 
    P.Title AS PostTitle, 
    P.CreationDate AS PostDate, 
    COUNT(C.Comment) AS TotalComments 
FROM 
    Users U 
JOIN 
    Posts P ON U.Id = P.OwnerUserId 
LEFT JOIN 
    Comments C ON P.Id = C.PostId 
WHERE 
    P.PostTypeId = 1 -- Only Questions
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate 
ORDER BY 
    TotalComments DESC 
LIMIT 10;
