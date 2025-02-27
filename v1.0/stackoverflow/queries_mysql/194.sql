
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN B.Id END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN B.Id END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN B.Id END) AS BronzeBadges,
        SUM(COALESCE(U.UpVotes, 0) - COALESCE(U.DownVotes, 0)) AS NetVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        (@row_number := IF(@prev_owner_user_id = P.OwnerUserId, @row_number + 1, 1)) AS PopularRank,
        @prev_owner_user_id := P.OwnerUserId
    FROM 
        Posts P, (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
    ORDER BY P.OwnerUserId, P.Score DESC, P.ViewCount DESC
),
UsersWithPopularPosts AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        P.PostId,
        P.Title,
        P.Score
    FROM 
        UserBadgeCounts U
    JOIN 
        PopularPosts P ON U.UserId = P.OwnerUserId
    WHERE 
        P.PopularRank <= 3
)
SELECT 
    U.DisplayName,
    COALESCE(P.Title, 'No Popular Posts') AS PopularPostTitle,
    COALESCE(P.Score, 0) AS PostScore,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.NetVotes
FROM 
    UserBadgeCounts U
LEFT JOIN 
    UsersWithPopularPosts P ON U.UserId = P.UserId
ORDER BY 
    U.NetVotes DESC, U.GoldBadges DESC, U.SilverBadges DESC, U.BronzeBadges DESC
LIMIT 10;
