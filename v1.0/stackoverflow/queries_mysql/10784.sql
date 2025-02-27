
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    T.TagName,
    COUNT(C.Id) AS CommentsCount,
    COUNT(V.Id) AS VotesCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     WHERE 
        CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    ) AS T ON TRUE
WHERE 
    P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, U.Reputation, T.TagName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
