
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT PH.PostId) AS TotalClosedPosts,
        GROUP_CONCAT(DISTINCT CT.Name ORDER BY CT.Name SEPARATOR ', ') AS ClosedReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment = CAST(CT.Id AS CHAR)
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.AvgScore,
        COALESCE(CPS.TotalClosedPosts, 0) AS TotalClosedPosts,
        COALESCE(CPS.ClosedReasons, 'None') AS ClosedReasons,
        RANK() OVER (ORDER BY US.TotalPosts DESC) AS PostRank
    FROM 
        UserStats US
    LEFT JOIN 
        ClosedPostStats CPS ON US.UserId = CPS.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.AvgScore,
    TU.TotalClosedPosts,
    TU.ClosedReasons
FROM 
    TopUsers TU
WHERE 
    TU.PostRank <= 10
ORDER BY 
    TU.AvgScore DESC,
    TU.TotalPosts DESC;
