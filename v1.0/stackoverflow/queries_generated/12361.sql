-- Performance benchmarking query for StackOverflow schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, PT.Name
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.PostCount,
    U.CommentCount,
    U.TotalBounties,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.PostType,
    P.UpVotes,
    P.DownVotes
FROM 
    UserStats U
JOIN 
    PostStats P ON P.PostId IN (
        SELECT Id 
        FROM Posts 
        ORDER BY CreationDate DESC 
        LIMIT 10
    )
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
