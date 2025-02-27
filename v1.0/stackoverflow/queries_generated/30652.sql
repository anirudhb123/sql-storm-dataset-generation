WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        Level + 1
    FROM 
        Users U
    INNER JOIN 
        Posts P ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2022-01-01'
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.CreationDate,
    UA.LastAccessDate,
    COUNT(DISTINCT P.Id) AS PostCount,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
    MAX(P.CreationDate) AS LastPostDate,
    COUNT(DISTINCT C.Id) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounty,
    ROW_NUMBER() OVER (PARTITION BY UA.UserId ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS Rank
FROM 
    UserActivity UA
LEFT JOIN 
    Posts P ON UA.UserId = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
WHERE 
    UA.Level <= 3
GROUP BY 
    UA.UserId, UA.DisplayName, UA.Reputation, UA.CreationDate, UA.LastAccessDate
HAVING 
    COUNT(DISTINCT P.Id) > 5 
    OR SUM(COALESCE(P.ViewCount, 0)) > 1000
ORDER BY 
    TotalViewCount DESC;

-- Fetch detail of posts and their history types for the top users
WITH TopUsers AS (
    SELECT 
        UserId 
    FROM 
        UserActivity 
    WHERE 
        Level <= 3
    GROUP BY 
        UserId
    ORDER BY 
        COUNT(DISTINCT Id) DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    P.Title,
    P.CreationDate,
    P.Score,
    PH.Comment,
    PH.CreationDate AS HistoryDate,
    PHT.Name AS PostHistoryType
FROM 
    TopUsers TU
JOIN 
    Users U ON TU.UserId = U.Id
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    PostHistory PH ON P.Id = PH.PostId
JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    PH.CreationDate >= U.LastAccessDate
ORDER BY 
    U.DisplayName, P.CreationDate DESC;

