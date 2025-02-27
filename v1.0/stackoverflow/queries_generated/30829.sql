WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(V.VoteTypeId = 2) AS Upvotes,
        SUM(V.VoteTypeId = 3) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments 
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
),
PostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        DENSE_RANK() OVER (ORDER BY (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = U.Id) DESC) AS ActivityRank
    FROM Users U
    WHERE U.Reputation > 1000
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.CreationDate,
        (SELECT COUNT(*) FROM Votes WHERE PostId = PS.PostId AND VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = PS.PostId AND VoteTypeId = 3) AS DownvoteCount,
        U.DisplayName AS OwnerDisplayName
    FROM PostScores PS
    INNER JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE PS.PostRank <= 10
)
SELECT 
    U.DisplayName AS UserName,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBounties,
    US.Upvotes,
    US.Downvotes,
    COALESCE(TP.Title, 'No Posts') AS TopPostTitle,
    COALESCE(TP.CreationDate, 'N/A') AS TopPostDate,
    COALESCE(TP.Score, 0) AS TopPostScore,
    AU.ActivityRank AS UserActivityRank
FROM UserScores US
LEFT JOIN TopPosts TP ON US.UserId = TP.OwnerUserId
JOIN ActiveUsers AU ON US.UserId = AU.UserId
ORDER BY US.TotalPosts DESC, US.Upvotes DESC;
