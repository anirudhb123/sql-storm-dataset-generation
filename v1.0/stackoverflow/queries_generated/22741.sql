WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(B.Class) AS TotalBadgeClass,
        SUM(B.Class * (CASE WHEN B.TagBased = 1 THEN 1 ELSE 0 END)) AS TagBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPostHistories AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS ClosedPostCount,
        MIN(PH.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.Reputation,
        COUNT(DISTINCT RP.PostId) AS RecentPostCount,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(CP.FirstClosedDate, '1970-01-01'::timestamp) AS FirstClosedDate
    FROM 
        UserBadges UB
    LEFT JOIN 
        RecentPosts RP ON UB.UserId = RP.OwnerUserId AND RP.RecentPostRank <= 5
    LEFT JOIN 
        ClosedPostHistories CP ON UB.UserId = CP.UserId
    WHERE 
        UB.Reputation > 100
    GROUP BY 
        UB.UserId, UB.DisplayName, UB.Reputation, CP.ClosedPostCount, CP.FirstClosedDate
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.RecentPostCount,
    TU.ClosedPostCount,
    CASE 
        WHEN TU.ClosedPostCount = 0 THEN 'Never Closed a Post'
        ELSE 'First Closed on: ' || TO_CHAR(TU.FirstClosedDate, 'YYYY-MM-DD')
    END AS ClosedPostStatus,
    SUM(UB.GoldBadges) AS TotalGoldBadges,
    SUM(UB.SilverBadges) AS TotalSilverBadges,
    SUM(UB.BronzeBadges) AS TotalBronzeBadges,
    (SUM(UB.GoldBadges) + SUM(UB.SilverBadges) + SUM(UB.BronzeBadges)) AS TotalBadges,
    (SUM(UB.TagBadges) / NULLIF(SUM(UB.GoldBadges + UB.SilverBadges + UB.BronzeBadges), 0)) * 100 AS TagBadgePercentage
FROM 
    TopUsers TU
JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
GROUP BY 
    TU.DisplayName, TU.Reputation, TU.RecentPostCount, TU.ClosedPostCount, TU.FirstClosedDate
ORDER BY 
    TU.Reputation DESC NULLS LAST, 
    TotalBadges DESC
LIMIT 10;
This SQL query captures various constructs and constructs a performance benchmarking scenario that summarizes user activities and achievements in the Stack Overflow environment. It includes CTEs for organization, complex aggregates, NULL logic, and computes insights into users’ activities, badges, and their ratio of tagged badges to total badges. Additionally, it addresses potential semantic corner cases, like avoiding division by zero when calculating the tag badge percentage.
