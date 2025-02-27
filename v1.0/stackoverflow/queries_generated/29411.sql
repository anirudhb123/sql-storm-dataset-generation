WITH TagAggregates AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.Id, T.TagName
),
PopularTags AS (
    SELECT 
        TagId, 
        TagName, 
        PostCount, 
        TotalViews,
        TotalComments,
        TotalAnswers,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank
    FROM 
        TagAggregates
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank,
        RANK() OVER (ORDER BY COUNT(DISTINCT C.Id) DESC) AS CommentRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
FinalReport AS (
    SELECT 
        PT.TagId,
        PT.TagName,
        PT.PostCount,
        PT.TotalViews,
        PT.TotalComments,
        PT.TotalAnswers,
        UA.UserId,
        UA.DisplayName AS TopUser,
        UA.PostsCreated,
        UA.CommentsMade,
        UA.TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY PT.TagId ORDER BY UA.PostsCreated DESC) AS UserRank
    FROM 
        PopularTags PT
    LEFT JOIN 
        UserActivity UA ON UA.PostsCreated > 0
)
SELECT 
    TagId,
    TagName,
    PostCount,
    TotalViews,
    TotalComments,
    TotalAnswers,
    TopUser,
    PostsCreated,
    CommentsMade,
    TotalBounties
FROM 
    FinalReport
WHERE 
    UserRank = 1
ORDER BY 
    TotalViews DESC, TotalComments DESC, TotalAnswers DESC;
