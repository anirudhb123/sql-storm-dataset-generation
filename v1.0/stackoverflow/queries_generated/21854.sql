WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), 
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate,
        MAX(P.Score) AS HighestScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        US.BadgeCount,
        US.GoldBadges,
        US.SilverBadges,
        US.BronzeBadges,
        RPS.PostCount,
        RPS.TotalViews,
        RPS.LastPostDate,
        RPS.HighestScore,
        CASE 
            WHEN RPS.PostCount > 0 THEN RPS.TotalViews::FLOAT / RPS.PostCount 
            ELSE 0 
        END AS AverageViewsPerPost,
        CASE 
            WHEN RPS.PostCount > 0 THEN RPS.HighestScore::FLOAT / RPS.PostCount 
            ELSE 0 
        END AS AverageScorePerPost
    FROM 
        UserStats US
    LEFT JOIN 
        RecentPostStats RPS ON US.UserId = RPS.OwnerUserId
    WHERE 
        US.Reputation >= 1000 AND 
        US.CreationDate <= NOW() - INTERVAL '2 year'
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.PostCount,
    U.TotalViews,
    U.LastPostDate,
    U.HighestScore,
    U.AverageViewsPerPost,
    U.AverageScorePerPost,
    CASE 
        WHEN U.AverageScorePerPost >= 5 THEN 'High Performer' 
        ELSE 'Regular Contributor' 
    END AS PerformanceCategory
FROM 
    UserPerformance U
ORDER BY 
    U.Reputation DESC, 
    U.PostCount DESC
LIMIT 50;

-- Including subqueries to get closure reasons for recently closed posts
SELECT 
    UP.DisplayName,
    PH.Comment AS CloseReason,
    PH.CreationDate AS CloseDate
FROM 
    UserPerformance UP
JOIN 
    PostHistory PH ON UP.UserId = PH.UserId
WHERE 
    PH.PostHistoryTypeId = 10 
    AND PH.CreationDate >= NOW() - INTERVAL '3 months'
ORDER BY 
    PH.CreationDate DESC;

-- A strange scenario where we are looking for users without a reputation but possess badges
SELECT 
    U.DisplayName,
    U.Reputation,
    B.Name AS BadgeName
FROM 
    Users U
JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation IS NULL
ORDER BY 
    B.Date DESC;
