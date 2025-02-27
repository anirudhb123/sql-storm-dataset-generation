
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        PostCount,
        CommentCount,
        @rank := IF(@prevReputation = Reputation, @rank + 1, 1) AS Rank,
        @prevReputation := Reputation
    FROM 
        UserScore, (SELECT @rank := 0, @prevReputation := NULL) AS vars
    ORDER BY 
        Reputation DESC, Upvotes DESC
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        @rank2 := IF(@prevScore = Score, @rank2 + 1, 1) AS Rank,
        @prevScore := Score
    FROM 
        PostStats, (SELECT @rank2 := 0, @prevScore := NULL) AS vars
    ORDER BY 
        Score DESC, TotalUpvotes DESC
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    U.Upvotes AS UserUpvotes,
    U.Downvotes AS UserDownvotes,
    U.PostCount AS UserPostCount,
    U.CommentCount AS UserCommentCount,
    P.Title AS TopPost,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.TotalComments AS PostCommentCount,
    P.TotalUpvotes AS PostTotalUpvotes,
    P.TotalDownvotes AS PostTotalDownvotes
FROM 
    TopUsers U
JOIN 
    TopPosts P ON U.Rank = 1 AND P.Rank = 1 
WHERE 
    U.UserId = P.PostId
ORDER BY 
    U.Reputation DESC;
