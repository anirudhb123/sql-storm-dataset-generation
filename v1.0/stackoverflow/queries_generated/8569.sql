WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty,
        COALESCE(SUM(V.CreationDate), 0) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        TotalBounty,
        TotalVotes,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalVotes DESC) AS Rank
    FROM UserMetrics
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBadges,
    tu.TotalBounty,
    tu.TotalVotes
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.Rank;
