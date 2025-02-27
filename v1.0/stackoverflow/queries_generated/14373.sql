-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN P.CreationDate >= NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.PostTypeId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.UpVotes,
    U.DownVotes,
    U.RecentPosts,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.CreationDate AS PostCreationDate,
    P.OwnerDisplayName,
    P.PostTypeId
FROM 
    UserStats U
LEFT JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC,
    P.Score DESC
LIMIT 100;
