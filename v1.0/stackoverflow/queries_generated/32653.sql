WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.CreationDate,
        P2.Score,
        P2.OwnerUserId,
        Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostCTE R ON R.PostId = P2.ParentId
)

SELECT 
    U.DisplayName AS Owner,
    R.Title,
    R.CreationDate,
    R.Score,
    R.Level,
    COALESCE(C.Count, 0) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = R.PostId AND V.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = R.PostId AND V.VoteTypeId = 3) AS DownVoteCount
FROM 
    RecursivePostCTE R
LEFT JOIN 
    Users U ON R.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON R.PostId = C.PostId
WHERE 
    (R.CreationDate >= NOW() - INTERVAL '30 days') -- Posts created in the last 30 days
    AND (R.Score >= 10 OR R.Level > 1) -- High scoring questions or those with answers
ORDER BY 
    R.Score DESC, R.CreationDate DESC
LIMIT 100;
