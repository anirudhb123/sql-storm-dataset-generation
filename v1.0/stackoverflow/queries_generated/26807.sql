WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE 
            WHEN V.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS TotalUpvotes,
        SUM(CASE 
            WHEN V.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
UserEngagement AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBounty,
        TotalUpvotes,
        TotalDownvotes,
        (TotalUpvotes - TotalDownvotes) AS NetVotes,
        CASE 
            WHEN TotalPosts > 0 THEN (TotalBounty / TotalPosts)::float 
            ELSE 0 
        END AS AverageBountyPerPost
    FROM UserActivity
),
TopActiveUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM UserEngagement
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    LastAccessDate,
    TotalPosts,
    TotalComments,
    TotalBadges,
    TotalBounty,
    TotalUpvotes,
    TotalDownvotes,
    NetVotes,
    AverageBountyPerPost,
    PostRank,
    CommentRank
FROM TopActiveUsers
WHERE PostRank <= 10 OR CommentRank <= 10
ORDER BY NetVotes DESC, Reputation DESC;
