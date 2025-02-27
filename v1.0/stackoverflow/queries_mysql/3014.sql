
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        @row_number := IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner_user_id := P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS init
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS SIGNED) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.Location,
    UBadge.GoldBadges,
    UBadge.SilverBadges,
    UBadge.BronzeBadges,
    PD.Title AS RecentPostTitle,
    PD.CreationDate AS RecentPostDate,
    PD.TotalBounty,
    CP.CloseReason AS RecentlyClosedReason,
    COUNT(DISTINCT CP.PostId) AS TotalClosedPosts
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UBadge ON U.Id = UBadge.UserId
LEFT JOIN 
    PostDetails PD ON U.Id = PD.OwnerUserId AND PD.PostRank = 1
LEFT JOIN 
    ClosedPosts CP ON PD.PostId = CP.PostId
WHERE 
    U.Reputation >= 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Location, 
    UBadge.GoldBadges, UBadge.SilverBadges, UBadge.BronzeBadges, 
    PD.Title, PD.CreationDate, PD.TotalBounty, CP.CloseReason
HAVING 
    COUNT(DISTINCT CP.PostId) > 0
ORDER BY 
    U.Reputation DESC, U.CreationDate ASC;
