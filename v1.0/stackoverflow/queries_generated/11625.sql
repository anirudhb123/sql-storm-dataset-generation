-- Performance benchmarking query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
TopPostAuthors AS (
    SELECT 
        UserId,
        PostCount,
        TotalViews,
        TotalBounty,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS RN
    FROM UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    TP.PostCount,
    TP.TotalViews,
    TP.TotalBounty,
    TP.BadgeCount
FROM TopPostAuthors TP
JOIN Users U ON U.Id = TP.UserId
WHERE TP.RN <= 10
ORDER BY TP.PostCount DESC;
