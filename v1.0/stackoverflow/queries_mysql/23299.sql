
WITH RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        @rank := IF(@prev_post_type = P.PostTypeId, @rank + 1, 1) AS Rank,
        @prev_post_type := P.PostTypeId
    FROM 
        Posts P,
        (SELECT @rank := 0, @prev_post_type := NULL) AS vars
    WHERE 
        P.Score IS NOT NULL AND 
        P.ViewCount IS NOT NULL
    ORDER BY 
        P.PostTypeId, P.Score DESC, P.CreationDate DESC
),

UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalViews,
    UA.UpVotesReceived,
    UA.DownVotesReceived,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'No badges') AS Badges,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViews,
    TP.Score AS TopPostScore
FROM 
    RecentUserActivity UA
LEFT JOIN 
    UserBadgeCount UB ON UA.UserId = UB.UserId
LEFT JOIN 
    TopPosts TP ON UA.UserId = (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = TP.PostId LIMIT 1)
WHERE 
    UA.Reputation > 1000
ORDER BY 
    UA.Reputation DESC, 
    UA.TotalViews DESC
LIMIT 10;
