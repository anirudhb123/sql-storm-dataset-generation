-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        U.DisplayName AS OwnerName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.TotalBounty,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.CreationDate,
    P.OwnerName
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, -- Sorting by Reputation to see top users
    P.ViewCount DESC   -- Sorting by most viewed posts
LIMIT 100; -- Limiting to top 100 for benchmarking
