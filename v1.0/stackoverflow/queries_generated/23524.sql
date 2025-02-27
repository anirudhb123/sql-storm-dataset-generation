WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        CommentCount,
        PostCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) as Rank
    FROM 
        UserStats
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CommentCount,
        COALESCE(UP.UserId, -1) AS EngagedUserId, -- -1 indicates no engagement
        COUNT(C.Id) AS CommentEngagement,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpvoteEngagement,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownvoteEngagement
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        (SELECT DISTINCT UserId, PostId FROM Votes WHERE VoteTypeId = 2) UP ON P.Id = UP.PostId
    GROUP BY 
        P.Id, UP.UserId
),
FinalBenchmark AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        T.ViewCount,
        COALESCE(T.CommentEngagement, 0) AS CommentEngagement,
        COALESCE(T.UpvoteEngagement, 0) AS UpvoteEngagement,
        COALESCE(T.DownvoteEngagement, 0) AS DownvoteEngagement,
        ROW_NUMBER() OVER (PARTITION BY T.PostId ORDER BY T.CommentEngagement DESC) AS PostRank
    FROM 
        TopUsers U
    JOIN 
        PostEngagement T ON U.UserId = T.EngagedUserId
    WHERE 
        U.Reputation > 100 -- filtering to only show users with a respectable reputation
)
SELECT 
    DisplayName,
    Reputation,
    ViewCount,
    CommentEngagement,
    UpvoteEngagement,
    DownvoteEngagement,
    PostRank
FROM 
    FinalBenchmark
WHERE 
    PostRank = 1
ORDER BY 
    Reputation DESC,
    CommentEngagement DESC;
