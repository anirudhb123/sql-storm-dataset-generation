WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS Wikis,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.TotalBadges,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.Wikis,
        PS.TotalScore,
        PS.LastPostDate,
        RANK() OVER (PARTITION BY CASE WHEN PS.TotalPosts > 0 THEN 'Active' ELSE 'Inactive' END ORDER BY UB.TotalBadges DESC) AS BadgeRank
    FROM UserBadges UB
    LEFT JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        UA.DisplayName,
        UA.TotalBadges,
        COALESCE(UA.TotalPosts, 0) AS TotalPosts,
        COALESCE(UA.Questions, 0) AS Questions,
        COALESCE(UA.Answers, 0) AS Answers,
        COALESCE(UA.Wikis, 0) AS Wikis,
        COALESCE(UA.TotalScore, 0) AS TotalScore,
        UA.BadgeRank,
        CASE 
            WHEN UA.BadgeRank <= 10 THEN 'Top Contributor'
            WHEN UA.BadgeRank <= 50 THEN 'Frequent Contributor'
            ELSE 'New Member'
        END AS ContributorType
    FROM UserActivity UA
    WHERE UA.TotalPosts IS NOT NULL
),
InactiveUsers AS (
    SELECT 
        U.DisplayName,
        B.TotalBadges,
        'Inactive' AS Status
    FROM Users U
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    WHERE U.Id NOT IN (SELECT OwnerUserId FROM Posts)
),
AllUsers AS (
    SELECT * FROM TopUsers
    UNION ALL
    SELECT * FROM InactiveUsers
)
SELECT 
    *,
    CASE 
        WHEN TotalPosts = 0 THEN 'No Posts Yet'
        WHEN ContributorType = 'New Member' AND TotalBadges > 0 THEN 'Just Starting With Badges'
        ELSE 'Active Contributor'
    END AS ContributionStatus
FROM AllUsers
ORDER BY 
    CASE WHEN Status = 'Inactive' THEN 1 ELSE 0 END,
    TotalScore DESC,
    TotalBadges DESC;
