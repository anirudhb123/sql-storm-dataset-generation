WITH UserScoreDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 END) AS TotalPosts,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RecentActivityRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        TotalPosts,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RecentActivityRank,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserScoreDetails
),
EligiblePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AcceptedAnswerId,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS PostOwner,
        C.Comment AS CloseReason
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10 -- 10 = Post Closed
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
        AND P.Score BETWEEN 0 AND 100
)

SELECT 
    RU.DisplayName AS UserName,
    RU.Reputation AS UserReputation,
    RU.TotalBounty,
    RU.TotalPosts,
    RU.GoldBadges,
    RU.SilverBadges,
    RU.BronzeBadges,
    EP.Title AS QuestionTitle,
    EP.Score AS QuestionScore,
    EP.ViewCount AS QuestionViews,
    EP.PostOwner AS OwnerDisplayName,
    EP.CloseReason,
    CASE WHEN EP.AcceptedAnswerId IS NOT NULL THEN 'Accepted' ELSE 'Not Accepted' END AS AnswerStatus
FROM RankedUsers RU
JOIN EligiblePosts EP ON RU.UserId = EP.OwnerUserId
WHERE 
    RU.ReputationRank <= 10 -- Top 10 users by reputation
    AND (EP.CloseReason IS NULL OR EP.CloseReason <> '') -- Posts that are either open or have a non-empty close reason
ORDER BY 
    RU.Reputation DESC, 
    EP.CreationDate DESC;

-- Additional corner case with NULL logic:
SELECT 
    U.DisplayName AS UserName,
    COALESCE(B.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN U.Location IS NULL THEN 'Location Unknown'
        ELSE U.Location
    END AS UserLocation
FROM Users U
LEFT JOIN Badges B ON U.Id = B.UserId 
WHERE U.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY UserName;
