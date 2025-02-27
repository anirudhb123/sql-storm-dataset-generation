-- Performance Benchmarking Query to analyze Posts along with Users and their Badges
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COUNT(B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    P.Id, U.Id
ORDER BY 
    P.CreationDate DESC
LIMIT 100; -- Limit to 100 recent posts for performance checking
