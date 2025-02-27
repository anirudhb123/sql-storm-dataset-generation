WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        Posts PA ON P.ParentId = PA.Id -- Join on parent posts
    WHERE 
        PA.PostTypeId = 1
),
PostSummary AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        'Closed' AS Status
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10  -- Posts voted to be closed
)
SELECT 
    PS.DisplayName,
    PS.TotalPosts,
    PS.TotalAnswers,
    PS.TotalComments,
    PS.TotalViews,
    PS.AverageScore,
    CP.Status,
    COUNT(DISTINCT RP.PostId) AS RelatedPostsCount
FROM 
    PostSummary PS
LEFT JOIN 
    ClosedPosts CP ON PS.TotalPosts > 0  -- Filtering for users with posts
LEFT JOIN 
    RecursiveCTE RP ON PS.TotalPosts > 0 AND RP.OwnerUserId = PS.OwnerUserId 
GROUP BY 
    PS.DisplayName, 
    PS.TotalPosts, 
    PS.TotalAnswers, 
    PS.TotalComments, 
    PS.TotalViews, 
    PS.AverageScore, 
    CP.Status
HAVING 
    PS.TotalPosts > 5  -- Only include users with more than 5 total posts
ORDER BY 
    PS.AverageScore DESC, 
    PS.TotalPosts DESC;
