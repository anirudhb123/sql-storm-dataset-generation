WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    WHERE 
        U.Reputation > 500
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT PH.PostId) AS TotalClosedPosts
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.TotalBounty,
        COALESCE(CS.TotalClosedPosts, 0) AS TotalClosedPosts
    FROM 
        UserPostStats U
    LEFT JOIN 
        ClosedPostStats CS ON U.UserId = CS.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalBounty,
    TU.TotalClosedPosts,
    COALESCE(STRING_AGG(DISTINCT T.TagName, ', '), 'No Tags') AS AssociatedTags
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    STRING_TO_ARRAY(P.Tags, ', ') AS Tags ON TRUE
LEFT JOIN 
    Tags T ON T.TagName = TRIM(BOTH ' ' FROM Tags)
WHERE 
    TU.PostRank <= 10
GROUP BY 
    TU.DisplayName, TU.TotalPosts, TU.TotalQuestions, TU.TotalAnswers, TU.TotalBounty, TU.TotalClosedPosts
ORDER BY 
    TU.TotalPosts DESC;
