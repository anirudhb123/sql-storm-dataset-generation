
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        @row_number:=IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1) AS rn,
        @prev_owner_user_id:=P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
),
AcceptedAnswers AS (
    SELECT 
        P.AcceptedAnswerId AS AnswerId,
        COUNT(P.AcceptedAnswerId) AS AcceptedCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2
    GROUP BY 
        P.AcceptedAnswerId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    COALESCE(P.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(P.CreationDate, NULL) AS LastPostDate,
    COALESCE(P.Score, 0) AS LastPostScore,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    COALESCE(A.AcceptedCount, 0) AS AcceptedCount
FROM 
    UserBadges UB
LEFT JOIN 
    RecentPosts P ON UB.UserId = P.OwnerUserId 
    AND P.rn = 1
LEFT JOIN 
    AcceptedAnswers A ON A.AnswerId = P.PostId
WHERE 
    (UB.BadgeCount > 0 OR P.PostId IS NOT NULL)
ORDER BY 
    UB.DisplayName ASC, 
    P.CreationDate DESC
LIMIT 50;
