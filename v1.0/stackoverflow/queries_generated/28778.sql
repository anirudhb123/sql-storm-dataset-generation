WITH UsersBadgeCount AS (
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
PostsWithDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
TopActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount,
        COALESCE(COUNT(P.Id), 0) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    WHERE 
        U.Reputation > 1000 -- Only users with reputation greater than 1000
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        TotalViewCount DESC
    LIMIT 10
)
SELECT 
    T.ActiveUserId AS UserId,
    T.ActiveUserName AS DisplayName,
    B.BadgeCount,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    P.Title AS TopPostTitle,
    P.ViewCount AS PostViewCount,
    P.Score AS PostScore,
    P.CommentCount
FROM 
    TopActiveUsers T
JOIN 
    UsersBadgeCount B ON T.UserId = B.UserId
JOIN 
    PostsWithDetails P ON T.UserId = P.OwnerUserId 
ORDER BY 
    B.BadgeCount DESC, 
    T.TotalViewCount DESC
LIMIT 10;
