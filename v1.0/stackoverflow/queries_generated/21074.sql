WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS TotalUpvotes,  -- Count of Upvotes (VoteTypeId = 2)
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS TotalDownvotes,  -- Count of Downvotes (VoteTypeId = 3)
        DATEDIFF(CURRENT_TIMESTAMP, U.CreationDate) AS DaysActive
    FROM Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswer,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, -- Total Upvotes for a post
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount, -- Total Downvotes for a post
        RANK() OVER (ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
FinalMetrics AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.TotalPosts,
        U.TotalUpvotes,
        U.TotalDownvotes,
        U.DaysActive,
        P.Title,
        P.CommentCount,
        P.UpVoteCount,
        P.DownVoteCount,
        P.PostRank
    FROM UserMetrics U
    JOIN PostStatistics P ON U.UserId = P.OwnerUserId
    WHERE U.Reputation > 1000
),
UserRanking AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM FinalMetrics
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalUpvotes,
    TotalDownvotes,
    DaysActive,
    Title,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    PostRank,
    ReputationRank
FROM UserRanking
WHERE ReputationRank <= 10
ORDER BY Reputation DESC, TotalPosts DESC;

-- Retrieve posts that are potentially problematic based on metrics
WITH ProblematicPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CloseDate,
        COUNT(C.CreationDate) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        CASE 
            WHEN ((P.CloseDate IS NOT NULL) AND (SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END) > 0)) 
                THEN 'Closed and Voted for Closure'
            ELSE 'Open or Not Voted for Closure'
        END AS Status
    FROM Posts P
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.ViewCount < 10 AND (P.CloseDate IS NULL OR P.CloseDate > DATEADD(DAY, -30, CURRENT_TIMESTAMP))
    GROUP BY P.Id, P.Title, P.ViewCount, P.CloseDate
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CommentCount,
    DownVoteCount,
    Status
FROM ProblematicPosts
WHERE DownVoteCount > 5;

-- This query aggregates various metrics about users with significant reputation and their posts while also identifying problematic posts.
