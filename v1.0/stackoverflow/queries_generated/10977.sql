-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves performance metrics across various tables, including post statistics, user engagement, and vote counts.

SELECT 
    P.Id AS PostId,
    P.Title,
    PT.Name AS PostType,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS VoteCount,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    COALESCE(NULLIF(P.Score, 0), 0) AS Score,
    P.ViewCount,
    P.CreationDate,
    P.LastActivityDate,
    (SELECT COUNT(*) FROM Posts WHERE ParentId = P.Id) AS AnswerCount
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year' -- Consider posts created in the last year
GROUP BY 
    P.Id, P.Title, PT.Name, U.DisplayName
ORDER BY 
    P.LastActivityDate DESC;
