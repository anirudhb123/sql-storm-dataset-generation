WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Selecting only questions
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        COALESCE(MAX(RP.PostRank), 0) AS MostRecentPostRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users) -- Above average reputation
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
),
PostClosureReasons AS (
    SELECT 
        PH.PostId, 
        COUNT(DISTINCT PH.Comment) AS CloseReasonCount,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS ClosureReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    COALESCE(PR.PostId, 0) AS LastPostedQuestion, 
    COALESCE(PR.Title, 'No Posts') AS LastPostTitle,
    COALESCE(PR.CreationDate, 'N/A') AS LastPostDate,
    COALESCE(CR.CloseReasonCount, 0) AS TimesClosed,
    COALESCE(CR.ClosureReasons, 'None') AS ClosureReasonDetails
FROM 
    TopUsers U
LEFT JOIN 
    RankedPosts PR ON U.Id = PR.OwnerUserId AND PR.PostRank = 1 -- Last posted question
LEFT JOIN 
    PostClosureReasons CR ON PR.PostId = CR.PostId
WHERE 
    U.BadgeCount > 2 -- Users with more than 2 badges
ORDER BY 
    U.Reputation DESC,
    U.GoldBadges DESC,
    U.SilverBadges DESC;
