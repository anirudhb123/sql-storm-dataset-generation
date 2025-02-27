WITH RecursivePostScore AS (
    SELECT
        P.Id AS PostId,
        P.Score,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswer,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Only Questions
    UNION ALL
    SELECT
        A.Id AS PostId,
        A.Score,
        COALESCE(A.AcceptedAnswerId, 0),
        Level + 1
    FROM Posts A
    JOIN RecursivePostScore R ON R.PostId = A.ParentId
    WHERE A.PostTypeId = 2  -- Only Answers
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    GROUP BY U.Id
),
FilteredBadges AS (
    SELECT
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    WHERE B.Class = 1 -- Gold badges
    GROUP BY B.UserId
)
SELECT
    U.DisplayName,
    COALESCE(Top.TotalBounty, 0) AS TotalBounty,
    COALESCE(Top.TotalPosts, 0) AS TotalPosts,
    COALESCE(Top.TotalScore, 0) AS TotalScore,
    COALESCE(FB.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(FB.BadgeNames, 'None') AS GoldBadges,
    COUNT(DISTINCT R.PostId) AS LinkedPostCount
FROM Users U
LEFT JOIN TopUsers Top ON U.Id = Top.UserId
LEFT JOIN FilteredBadges FB ON U.Id = FB.UserId
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN PostLinks PL ON P.Id = PL.PostId
LEFT JOIN RecursivePostScore R ON P.Id = R.PostId
WHERE U.Reputation > 1000 -- Only users with a reputation above 1000
GROUP BY U.Id, Top.TotalBounty, Top.TotalPosts, Top.TotalScore, FB.BadgeCount, FB.BadgeNames
ORDER BY TotalScore DESC, TotalBounty DESC;
