
SELECT 
    U.DisplayName AS UserDisplayName, 
    P.Title AS PostTitle, 
    P.CreationDate AS PostCreationDate, 
    C.Text AS CommentText, 
    C.CreationDate AS CommentCreationDate 
FROM 
    Comments C
JOIN 
    Posts P ON C.PostId = P.Id
JOIN 
    Users U ON C.UserId = U.Id
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    C.Text, 
    C.CreationDate 
ORDER BY 
    C.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
