WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.CreationDate,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.EmailHash,
        U.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalViews,
        RANK() OVER (ORDER BY UPS.TotalViews DESC) AS ViewRank
    FROM 
        Users U
    JOIN 
        UserPostStats UPS ON U.Id = UPS.UserId
    WHERE 
        UPS.TotalPosts > 0
)
SELECT 
    U.DisplayName AS UserName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalViews,
    RPT.PostId AS RelatedPostId,
    RPT.Title AS RelatedPostTitle,
    RPT.CreationDate AS RelatedPostCreationDate,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotesCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    Posts P ON UPS.TotalPosts > 0 AND P.OwnerUserId = UPS.UserId
LEFT JOIN 
    RecursivePostHierarchy RPT ON P.Id = RPT.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    UPS.TotalPosts > 0
GROUP BY 
    U.DisplayName, UPS.TotalPosts, UPS.TotalQuestions, UPS.TotalAnswers, UPS.TotalViews, RPT.PostId, RPT.Title, RPT.CreationDate
HAVING 
    COUNT(W.ModerationHistoryTypeId IS NOT NULL) > 1
ORDER BY 
    UPS.TotalViews DESC
FETCH FIRST 10 ROWS ONLY;
