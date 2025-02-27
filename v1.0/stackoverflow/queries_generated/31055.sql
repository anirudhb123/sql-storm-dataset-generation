WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        P.AnswerCount,
        P.ViewCount,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
    UNION ALL
    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.CreationDate,
        P2.Score,
        P2.OwnerUserId,
        P2.AnswerCount,
        P2.ViewCount,
        Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        Posts P1 ON P2.ParentId = P1.Id
    WHERE 
        P2.PostTypeId = 2
)

, UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

, LatestPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Tags,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Tags IS NOT NULL AND P.PostTypeId = 1
)

SELECT 
    RCTE.PostId,
    RCTE.Title,
    RCTE.CreationDate,
    RCTE.Score,
    RCTE.ViewCount,
    RCTE.AnswerCount,
    UVS.UserId,
    UVS.DisplayName,
    UVS.TotalVotes,
    UVS.UpVotes,
    UVS.DownVotes,
    LP.Title AS LatestPostTitle,
    LP.Tags AS LatestPostTags
FROM 
    RecursiveCTE RCTE
LEFT JOIN 
    UserVoteStats UVS ON RCTE.OwnerUserId = UVS.UserId
LEFT JOIN 
    LatestPosts LP ON RCTE.PostId = LP.Id AND LP.RN = 1
WHERE 
    RCTE.Level = 1 
    AND (RCTE.Score > 5 OR RCTE.ViewCount > 100)
ORDER BY 
    RCTE.Score DESC, RCTE.ViewCount DESC;

-- Including a count of posts by type
SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS PostCount
FROM 
    PostTypes PT
LEFT JOIN 
    Posts P ON PT.Id = P.PostTypeId
GROUP BY 
    PT.Name
ORDER BY 
    PostCount DESC;

-- Calculate statistics related to badges
SELECT 
    B.Name AS BadgeName,
    COUNT(B.UserId) AS UsersAwarded,
    MAX(B.Date) AS LastAwardedDate
FROM 
    Badges B
GROUP BY 
    B.Name
HAVING 
    COUNT(B.UserId) > 10
ORDER BY 
    UsersAwarded DESC;

