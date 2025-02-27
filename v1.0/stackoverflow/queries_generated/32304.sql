WITH RecursivePostScores AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(P.Score, 0) AS Score, 
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        A.ParentId,
        PS.Score + COALESCE(A.Score, 0), 
        Level + 1
    FROM 
        Posts A
    JOIN 
        RecursivePostScores PS ON A.Id = PS.PostId
    WHERE 
        A.PostTypeId = 2 -- Traverse answers
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users U
    LEFT OUTER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        PH.PostId
),
ActivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(CP.FirstClosedDate, P.LastActivityDate) AS LastRelevantDate
    FROM 
        Posts P
    LEFT JOIN 
        ClosedPosts CP ON P.Id = CP.PostId
    WHERE 
        P.PostTypeId = 1
    AND 
        P.LastActivityDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.TotalViews,
    COUNT(DISTINCT AP.Id) AS TotalActivePosts,
    AVG(RPS.Score) AS AveragePostScore,
    COUNT(DISTINCT RPS.PostId) AS TotalAnsweredQuestions,
    SUM(CASE WHEN RPS.Level > 0 THEN 1 ELSE 0 END) AS TotalAnswers
FROM 
    TopUsers RU
JOIN 
    ActivePosts AP ON RU.UserId = AP.OwnerUserId
LEFT JOIN 
    RecursivePostScores RPS ON AP.Id = RPS.PostId
WHERE 
    RU.ViewRank <= 10 -- Top 10 users by view count
GROUP BY 
    RU.UserId, RU.DisplayName
HAVING 
    COUNT(DISTINCT AP.Id) >= 5 -- Only consider users with at least 5 active posts
ORDER BY 
    RU.TotalViews DESC;
