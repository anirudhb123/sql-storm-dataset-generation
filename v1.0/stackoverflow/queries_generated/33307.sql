WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        0 AS TotalPosts,
        0 AS TotalVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
    UNION ALL
    SELECT 
        P.OwnerUserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        UA.TotalPosts + 1,
        UA.TotalVotes,
        UA.TotalQuestions,
        UA.TotalAnswers
    FROM 
        Posts P
    JOIN 
        UserActivity UA ON P.OwnerUserId = UA.UserId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
, PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
, TopVotedPosts AS (
    SELECT 
        PS.PostId,
        PS.VoteCount,
        PS.UpVotes,
        PS.DownVotes,
        ROW_NUMBER() OVER (ORDER BY PS.VoteCount DESC) AS PostRank
    FROM 
        PostVoteStats PS
    WHERE 
        PS.VoteCount > 0
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    COALESCE(TP.VoteCount, 0) AS TopPostVoteCount,
    COALESCE(TP.UpVotes, 0) AS TopPostUpVotes,
    COALESCE(TP.DownVotes, 0) AS TopPostDownVotes
FROM 
    UserActivity U
LEFT JOIN 
    TopVotedPosts TP ON U.TotalPosts = TP.PostRank
WHERE 
    U.Views > 1000
ORDER BY 
    U.Reputation DESC,
    U.TotalPosts DESC;
