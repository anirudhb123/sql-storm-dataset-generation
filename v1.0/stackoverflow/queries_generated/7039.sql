WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        PostCount, 
        TotalScore, 
        Upvotes, 
        Downvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        U.DisplayName AS OwnerName, 
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.LastActivityDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount,
        P.OwnerName, 
        P.Score, 
        P.CommentCount, 
        P.UpvoteCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        ActivePosts P
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    PU.Title,
    PU.CreationDate,
    PU.ViewCount,
    PU.Score,
    PU.CommentCount,
    PU.UpvoteCount
FROM 
    TopUsers TU
JOIN 
    PostStats PU ON TU.UserId = P.OwnerUserId
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, PU.Score DESC;
