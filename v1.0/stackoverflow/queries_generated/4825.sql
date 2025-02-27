WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.AuthorizedFlag = TRUE THEN 1 ELSE 0 END) AS AuthorizedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
ClosedPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS ClosedCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND
        P.ClosedDate IS NOT NULL
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName, 
    COALESCE(US.TotalPosts, 0) AS TotalPosts,
    COALESCE(US.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(US.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(CP.ClosedCount, 0) AS ClosedPostCount,
    RAT.LastPostDate
FROM 
    Users U
LEFT JOIN 
    UserStatistics US ON U.Id = US.UserId
LEFT JOIN 
    ClosedPosts CP ON U.Id = CP.OwnerUserId
LEFT JOIN 
    RecentActivity RAT ON U.Id = RAT.UserId
WHERE 
    (COALESCE(US.TotalPosts, 0) > 10 OR COALESCE(CP.ClosedCount, 0) > 0)
ORDER BY 
    COALESCE(US.TotalPosts, 0) DESC, 
    COALESCE(CP.ClosedCount, 0) ASC;
