WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        1 AS Level
    FROM Users U
    WHERE U.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        Level + 1
    FROM Users U
    INNER JOIN RecursiveUserStats R ON U.Id = R.UserId
    WHERE R.Level < 5  -- limiting levels to avoid infinite recursion
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM Posts P
    WHERE P.CreationDate >= '2021-01-01' 
    GROUP BY P.OwnerUserId
),
InteractionCounts AS (
    SELECT 
        C.UserId,
        COUNT(DISTINCT C.PostId) AS CommentCount,
        SUM(V.BountyAmount) AS BountyTotal
    FROM Comments C
    LEFT JOIN Votes V ON C.PostId = V.PostId AND V.VoteTypeId IN (1, 2)  -- Only counting accepted answers and upvotes
    GROUP BY C.UserId
),
UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.PostCount, 0) AS TotalPosts,
        COALESCE(I.CommentCount, 0) AS TotalComments,
        COALESCE(I.BountyTotal, 0) AS TotalBounties,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(P.AverageViews, 0) AS AverageViews
    FROM Users U
    LEFT JOIN PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN InteractionCounts I ON U.Id = I.UserId
),
FinalResult AS (
    SELECT 
        U.DisplayName,
        U.TotalPosts,
        U.TotalComments,
        CASE 
            WHEN U.TotalPosts = 0 THEN NULL 
            ELSE ROUND(CAST(U.TotalScore AS FLOAT) / U.TotalPosts, 2) 
        END AS AverageScore,
        U.TotalBounties,
        R.Reputation,
        R.Views,
        R.UpVotes,
        R.DownVotes
    FROM UserPostDetails U
    JOIN RecursiveUserStats R ON U.UserId = R.UserId
)
SELECT 
    F.DisplayName,
    F.TotalPosts,
    F.TotalComments,
    F.AverageScore,
    F.TotalBounties,
    F.Reputation,
    F.Views,
    F.UpVotes,
    F.DownVotes
FROM FinalResult F
WHERE F.AverageScore IS NOT NULL
ORDER BY F.AverageScore DESC
LIMIT 10;  -- Top 10 users with the highest average score per post
