
WITH UserBadges AS (
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
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        @row_number := IF(@current_user = P.OwnerUserId, @row_number + 1, 1) AS RN,
        @current_user := P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_number := 0, @current_user := NULL) r
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
),
PostVoteCounts AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UB.BadgeCount,
    COALESCE(RP.RN, 0) AS RecentPostCount,
    PV.UpVotes,
    PV.DownVotes,
    GROUP_CONCAT(P.TAGS SEPARATOR ', ') AS TagsAggregated
FROM 
    Users U
JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RN = 1
LEFT JOIN 
    PostVoteCounts PV ON PV.PostId = (
        SELECT P.AcceptedAnswerId 
        FROM Posts P 
        WHERE P.OwnerUserId = U.Id 
        AND P.PostTypeId = 1 
        LIMIT 1
    )
LEFT JOIN 
    Posts P ON P.OwnerUserId = U.Id
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL)
GROUP BY 
    U.DisplayName, U.Reputation, UB.BadgeCount, RP.RN, PV.UpVotes, PV.DownVotes
HAVING 
    COUNT(P.Id) > 1 
ORDER BY 
    U.Reputation DESC 
LIMIT 100;
