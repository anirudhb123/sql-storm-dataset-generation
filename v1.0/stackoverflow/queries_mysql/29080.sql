
WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        BadgeCount, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges,
        @user_rank := IF(@prev_badge_count = BadgeCount, @user_rank, @user_rank + 1) AS UserRank,
        @prev_badge_count := BadgeCount
    FROM 
        UserBadgeStats, (SELECT @user_rank := 0, @prev_badge_count := NULL) AS vars
    WHERE 
        BadgeCount > 0
    ORDER BY BadgeCount DESC
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        PD.PostId, 
        PD.Title, 
        PD.CreationDate, 
        PD.Score, 
        PD.CommentCount,
        @post_rank := IF(@prev_score = PD.Score, @post_rank, @post_rank + 1) AS PostRank,
        @prev_score := PD.Score
    FROM 
        PostDetails PD, (SELECT @post_rank := 0, @prev_score := NULL) AS vars
    WHERE 
        PD.CommentCount > 0
    ORDER BY PD.Score DESC
)
SELECT 
    U.DisplayName AS TopUser,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.Title AS TopPost,
    P.Score,
    P.CommentCount
FROM 
    TopUsers U
JOIN 
    TopPosts P ON P.CommentCount > 5
WHERE 
    U.UserRank <= 10 AND P.PostRank <= 10
ORDER BY 
    U.BadgeCount DESC, P.Score DESC;
