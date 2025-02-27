WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyEarned,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
), RecentActivity AS (
    SELECT 
        P.OwnerUserId,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS ActivityRank
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalBountyEarned,
        ReputationRank,
        RANK() OVER (ORDER BY Reputation DESC) AS OverallRank
    FROM UserStats
    WHERE Reputation > 1000
)

SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalBountyEarned,
    T.ReputationRank,
    R.ActivityRank,
    CASE WHEN T.TotalQuestions > 0 THEN 'Question Contributor' ELSE 'Post Contributor' END AS ContributorType,
    STRING_AGG(CASE WHEN R.ActivityRank <= 5 THEN CAST(P.Title AS VARCHAR) END, ', ') AS RecentTopPostTitles
FROM TopUsers T
LEFT JOIN RecentActivity R ON T.UserId = R.OwnerUserId
LEFT JOIN Posts P ON R.OwnerUserId = P.OwnerUserId AND R.ActivityRank = 1
GROUP BY T.UserId, T.DisplayName, T.TotalPosts, T.TotalQuestions, T.TotalBountyEarned, T.ReputationRank, R.ActivityRank
HAVING COUNT(P.Id) > 0
ORDER BY T.Reputation DESC, R.ActivityRank
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

-- Additional Audit Log Query; Analyzing Post Closure Reasons
SELECT 
    H.PostId,
    COUNT(CASE WHEN H.PostHistoryTypeId = 10 THEN 1 END) AS TotalClosed,
    STRING_AGG(CASE WHEN H.PostHistoryTypeId = 10 THEN CONCAT('Closed on ', H.CreationDate::DATE, ' by ', H.UserDisplayName) END, '; ') AS CloseDetails,
    COUNT(DISTINCT H.UserId) AS DistinctUsersClosed
FROM PostHistory H
INNER JOIN CloseReasonTypes C ON C.Id = CAST(H.Comment AS INT)
WHERE H.PostHistoryTypeId IN (10, 11) /* 10 for closed, 11 for reopened */
GROUP BY H.PostId
HAVING COUNT(CASE WHEN H.PostHistoryTypeId = 10 THEN 1 END) > 1
ORDER BY TotalClosed DESC;
