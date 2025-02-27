-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.BadgeCount,
    U.TotalBountyAmount,
    U.UpVotes,
    U.DownVotes,
    COUNT(DISTINCT PS.PostId) AS TotalPosts,
    SUM(PS.CommentCount) AS TotalComments,
    SUM(PS.VoteCount) AS TotalVotes,
    SUM(PS.AcceptedAnswerCount) AS TotalAcceptedAnswers
FROM 
    UserStats U
JOIN 
    PostStats PS ON U.UserId = PS.OwnerUserId
GROUP BY 
    U.UserId, U.DisplayName
ORDER BY 
    U.PostCount DESC;
