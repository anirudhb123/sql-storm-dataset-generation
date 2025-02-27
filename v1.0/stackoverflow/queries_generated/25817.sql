WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalQuestionScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
),
UserActivity AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(COALESCE(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END, 0)) AS CommentCount,
        SUM(COALESCE(B.Id IS NOT NULL, 0)) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.DisplayName
),
InfluentialPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT TAG.TagName) AS RelatedTags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><') AS TAG(TagName) ON TRUE
    WHERE 
        P.PostTypeId IN (1, 2) AND P.Score > 0
    GROUP BY 
        P.Id
    HAVING 
        COUNT(C.Id) >= 5
)
SELECT 
    T.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalAnswers,
    TS.TotalQuestionScore,
    UA.DisplayName AS ActiveUser,
    UA.PostsCreated,
    UA.TotalViews AS UserTotalViews,
    UA.CommentCount AS UserComments,
    UA.BadgeCount AS UserBadges,
    IP.Title AS InfluentialPostTitle,
    IP.Score AS InfluentialPostScore,
    IP.CommentCount AS InfluentialPostComments,
    IP.RelatedTags
FROM 
    TagStatistics TS
JOIN 
    UserActivity UA ON TS.PostCount > 0
JOIN 
    InfluentialPosts IP ON UA.PostsCreated > 10
ORDER BY 
    TS.TotalViews DESC, UA.TotalViews DESC, IP.Score DESC
LIMIT 10;
