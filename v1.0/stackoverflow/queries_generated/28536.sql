WITH TagStatistics AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT PH.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)

SELECT 
    T.TagName,
    TS.TotalPosts,
    TS.TotalQuestions,
    TS.TotalAnswers,
    TS.AverageScore,
    UA.DisplayName AS UserName,
    UA.PostsCount,
    UA.TotalBounty,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    PHD.HistoryCount,
    PHD.Editors
FROM 
    TagStatistics TS
LEFT JOIN 
    PostHistoryDetails PHD ON PHD.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || TS.TagName || '%')
LEFT JOIN 
    UserActivity UA ON UA.UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || TS.TagName || '%')
ORDER BY 
    TS.TotalPosts DESC,
    UA.TotalBounty DESC,
    TS.AverageScore DESC;
