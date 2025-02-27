-- Performance Benchmarking Query: Retrieve user reputation, their associated badges, and the posts they have created

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    B.Name AS BadgeName,
    B.Class AS BadgeClass,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    P.CreationDate DESC;
