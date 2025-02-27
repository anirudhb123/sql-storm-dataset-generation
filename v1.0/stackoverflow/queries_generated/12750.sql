-- Performance benchmarking query for the Stack Overflow schema

SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.Score AS PostScore,
    C.Text AS CommentText,
    C.CreationDate AS CommentDate,
    COUNT(V.Id) AS VoteCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1 -- Only questions
    AND P.CreationDate >= '2022-01-01' -- Replace with desired date range
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.Score, C.Text, C.CreationDate
ORDER BY 
    P.CreationDate DESC;
