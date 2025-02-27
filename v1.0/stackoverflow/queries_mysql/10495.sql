
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.Reputation AS OwnerReputation,
    U.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '<', -1)) AS TagName
     FROM Posts P
     JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
           UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
     WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1) AS T ON T.TagName IS NOT NULL
WHERE 
    P.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.DisplayName, T.TagName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
