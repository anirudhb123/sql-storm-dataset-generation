-- Performance benchmarking query to retrieve users with the highest reputation and their associated posts and comments
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    C.Id AS CommentId,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    U.Reputation > 1000 -- Filter for users with a significant reputation
ORDER BY 
    U.Reputation DESC, 
    P.CreationDate DESC 
LIMIT 100; -- Limit the output for benchmarking
