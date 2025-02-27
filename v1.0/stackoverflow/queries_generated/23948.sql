WITH UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(CASE WHEN COALESCE(CAST(P.Score AS integer), 0) > 0 THEN 1 ELSE 0 END), 0) AS Upvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
RecentActivity AS (
    SELECT
        UserId,
        COUNT(*) AS RecentActivePosts
    FROM Posts
    WHERE CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY UserId
),
TopBadges AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
)
SELECT
    U.Id AS UserID,
    U.DisplayName,
    U.Reputation,
    COALESCE(UE.TotalPosts, 0) AS TotalPosts,
    COALESCE(UE.Questions, 0) AS Questions,
    COALESCE(UE.Answers, 0) AS Answers,
    COALESCE(UE.Upvotes, 0) AS Upvotes,
    COALESCE(RA.RecentActivePosts, 0) AS RecentActivePosts,
    TB.BadgeNames,
    CASE 
        WHEN COALESCE(UE.Reputation, 0) >= 1000 THEN 'High Reputation'
        WHEN COALESCE(UE.Reputation, 0) BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    CASE
        WHEN EXISTS(SELECT 1 FROM Comments C WHERE C.UserId = U.Id AND C.CreationDate < NOW() - INTERVAL '60 days') THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM Users U
LEFT JOIN UserEngagement UE ON U.Id = UE.UserId
LEFT JOIN RecentActivity RA ON U.Id = RA.UserId
LEFT JOIN TopBadges TB ON U.Id = TB.UserId
WHERE U.Reputation > 0
ORDER BY U.Reputation DESC NULLS LAST
LIMIT 100;

This SQL query incorporates several advanced constructs:

- **Common Table Expressions (CTEs)**: Used to encapsulate user engagement metrics, recent activity within 30 days, and lists of top badges.
- **LEFT JOINs**: To aggregate related information from the Users, Posts, and Badges tables without eliminating users with no data in the other tables.
- **Correlated Subquery**: Within the CASE statement to check for active status based on comments made by users.
- **NULL handling**: The use of `COALESCE` to ensure NULL values are handled, providing defaults where applicable.
- **String Aggregation**: To compile all badge names into a single field.
- **Complicated predicates and calculations**: Different computation methods are applied to derive user metrics based on their activities and contributions.

This query serves as a performance benchmark for complex SQL operations, demonstrating the interaction of various features found in SQL.
