WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(U.Reputation) AS MaxReputation
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        COUNT(CASE WHEN P.PostTypeId = 3 THEN 1 END) AS Wikis,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.Wikis,
        PS.TotalScore,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (ORDER BY COALESCE(UB.BadgeCount, 0) DESC) AS BadgeRank
    FROM Users U
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation IS NOT NULL
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.BadgeCount,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.Wikis,
    TU.TotalScore,
    CASE 
        WHEN TU.ReputationRank <= 10 THEN 'Top Reputation'
        WHEN TU.BadgeCount > 5 THEN 'Very Badged User'
        ELSE 'Regular User'
    END AS UserClassification,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Posts P 
            WHERE P.OwnerUserId = TU.Id 
            AND P.AcceptedAnswerId IS NOT NULL
        ) THEN 'Has Accepted Answers'
        ELSE 'No Accepted Answers'
    END AS AnswerStatus,
    CASE 
        WHEN TU.BadgeRank <= 10 THEN 'Top Badged User'
        ELSE 'Regular Badged User'
    END AS BadgeStatus
FROM TopUsers TU
WHERE TU.TotalPosts > 0
ORDER BY TU.Reputation DESC, TU.BadgeCount DESC;

-- To include the nullable logic corner case
SELECT 
    u.DisplayName,
    COALESCE(pb.TotalPosts, 0) AS TotalPosts,
    COALESCE(badges.BadgeCount, 0) AS BadgeCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN p.AcceptedAnswerId IS NULL THEN 1 ELSE 0 END) AS UnacceptedAnswersCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN (
    SELECT U.Id, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
) badges ON u.Id = badges.Id
LEFT JOIN (
    SELECT OwnerUserId, COUNT(Id) AS TotalPosts
    FROM Posts 
    GROUP BY OwnerUserId
) pb ON u.Id = pb.OwnerUserId
GROUP BY u.DisplayName, pb.TotalPosts, badges.BadgeCount
HAVING COUNT(DISTINCT c.Id) > 0
ORDER BY u.DisplayName;
