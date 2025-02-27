WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.Reputation, U.CreationDate, U.DisplayName
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        UserId,
        SUM(Reputation) AS TotalReputation,
        SUM(TotalPosts) AS TotalPosts,
        SUM(TotalComments) AS TotalComments,
        SUM(TotalBounties) AS TotalBounties
    FROM UserStats
    GROUP BY UserId
    ORDER BY TotalReputation DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.TotalReputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBounties,
    P.Title AS RecentPostTitle,
    P.PostCreationDate,
    P.ViewCount,
    P.Score,
    P.PostType,
    P.OwnerDisplayName
FROM TopUsers U
JOIN PostDetails P ON U.UserId = P.OwnerDisplayName
ORDER BY U.TotalReputation DESC, P.PostCreationDate DESC;
