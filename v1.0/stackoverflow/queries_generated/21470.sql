WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounties,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  -- BountyStart
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.PostId) AS CloseCount,
        STRING_AGG(DISTINCT CTR.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CTR ON PH.Comment::int = CTR.Id
    WHERE PH.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY PH.PostId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UP.PostCount, 0) AS TotalPosts,
        COALESCE(CP.CloseCount, 0) AS TotalClosedPosts,
        COALESCE(CP.CloseReasons, 'None') AS CloseReasons
    FROM Users U
    LEFT JOIN UserStats UP ON U.Id = UP.UserId
    LEFT JOIN ClosedPosts CP ON U.Id = CP.PostId  -- Outer join to get closed posts
    WHERE U.Reputation > 1000  -- Only active users with a good reputation
),
TopPosters AS (
    SELECT 
        UserId,
        SUM(TotalPosts) AS FollowerCount,
        COUNT(*) AS UniqueClosedPosts
    FROM ActiveUsers 
    WHERE CloseReasons <> 'None'
    GROUP BY UserId
)
SELECT 
    AU.DisplayName,
    AU.Reputation,
    AU.TotalPosts,
    AU.TotalClosedPosts,
    AU.CloseReasons,
    CASE 
        WHEN AU.TotalClosedPosts > 0 THEN 'Active in Discussions'
        ELSE 'Lurker'
    END AS UserStatus,
    T.Width,
    COALESCE(T.FollowerCount, 0) AS Followers,
    R.ReputationRank
FROM ActiveUsers AU
JOIN UserStats R ON AU.UserId = R.UserId
LEFT JOIN TopPosters T ON AU.UserId = T.UserId
ORDER BY AU.Reputation DESC, AU.DisplayName ASC;

This query demonstrates several advanced SQL concepts including:

- Common Table Expressions (CTEs) to break down complex logic steps.
- Correlated subqueries to aggregate user statistics through multiple joins.
- Aggregating data to gather insights on user interactions, closed posts, and their reputation.
- Conditional logic to define user status based on criteria.
- Combining multiple joins with outer joins to derive a comprehensive dataset across different tables.
