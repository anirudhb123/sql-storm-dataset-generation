WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount IS NULL THEN 0 ELSE P.ViewCount END) AS TotalViews,
        SUM(CASE WHEN P.AnswerCount IS NULL THEN 0 ELSE P.AnswerCount END) AS TotalAnswers,
        SUM(CASE WHEN P.CommentCount IS NULL THEN 0 ELSE P.CommentCount END) AS TotalComments
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
), 
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    GROUP BY 
        P.Id
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalAnswers,
    TS.TotalComments,
    US.DisplayName AS TopUser,
    US.TotalPosts,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges,
    PA.Title AS ActivePostTitle,
    PA.CreationDate AS PostCreationDate,
    PA.ViewCount AS PostViewCount,
    PA.CommentCount AS TotalCommentsOnPost
FROM 
    TagStats TS
JOIN 
    UserStats US ON US.TotalPosts = (SELECT MAX(TotalPosts) FROM UserStats)
JOIN 
    PostActivity PA ON PA.ViewCount = (SELECT MAX(ViewCount) FROM PostActivity)
ORDER BY 
    TS.PostCount DESC
LIMIT 10;
