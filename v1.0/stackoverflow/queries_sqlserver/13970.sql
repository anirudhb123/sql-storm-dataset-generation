
WITH UserPosts AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS PostCount,
        SUM(ISNULL(Posts.Score, 0)) AS TotalScore,
        SUM(ISNULL(Posts.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(Posts.CommentCount, 0)) AS TotalComments,
        SUM(ISNULL(Posts.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id,
        Users.DisplayName
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    ISNULL(P.PostCount, 0) AS PostCount,
    ISNULL(P.TotalScore, 0) AS TotalScore,
    ISNULL(P.TotalViews, 0) AS TotalViews,
    ISNULL(P.TotalComments, 0) AS TotalComments,
    ISNULL(P.TotalAnswers, 0) AS TotalAnswers,
    ISNULL(B.BadgeCount, 0) AS BadgeCount,
    ISNULL(B.GoldBadges, 0) AS GoldBadges,
    ISNULL(B.SilverBadges, 0) AS SilverBadges,
    ISNULL(B.BronzeBadges, 0) AS BronzeBadges
FROM 
    Users U
LEFT JOIN 
    UserPosts P ON U.Id = P.UserId
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
ORDER BY 
    TotalScore DESC, 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
