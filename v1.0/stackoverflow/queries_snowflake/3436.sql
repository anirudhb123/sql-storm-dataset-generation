
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(IFF(V.VoteTypeId = 2, 1, 0), 0)) AS TotalUpvotes,
        SUM(COALESCE(IFF(V.VoteTypeId = 3, 1, 0), 0)) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName
),
RecentActivities AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS RecentPosts,
        COUNT(C.Id) AS RecentComments,
        COUNT(DISTINCT H.Id) AS PostEdits
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    LEFT JOIN Comments C ON P.Id = C.PostId AND C.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    LEFT JOIN PostHistory H ON P.Id = H.PostId AND H.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName
),
RankedUserEngagement AS (
    SELECT 
        UE.UserId,
        UE.DisplayName,
        UE.TotalViews,
        UE.TotalUpvotes,
        UE.TotalDownvotes,
        UE.TotalPosts,
        UE.TotalComments,
        R.RecentPosts,
        R.RecentComments,
        R.PostEdits,
        RANK() OVER (ORDER BY UE.TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY UE.TotalUpvotes DESC) AS UpvoteRank
    FROM UserEngagement UE
    LEFT JOIN RecentActivities R ON UE.UserId = R.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalViews,
    TotalUpvotes,
    TotalDownvotes,
    TotalPosts,
    TotalComments,
    RecentPosts,
    RecentComments,
    PostEdits,
    CASE 
        WHEN ViewRank <= 10 THEN 'Top Engaged Users'
        WHEN UpvoteRank <= 10 THEN 'Top Upvote Users'
        ELSE 'Regular Users'
    END AS UserCategory
FROM RankedUserEngagement
WHERE TotalComments > 10
ORDER BY TotalViews DESC, TotalUpvotes DESC
LIMIT 100;
