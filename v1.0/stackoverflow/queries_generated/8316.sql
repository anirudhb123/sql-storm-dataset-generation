WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(V.UserId IS NOT NULL) AS TotalVotes,
        SUM(COALESCE(CAST(P.Score AS INTEGER), 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalAcceptedAnswers,
        TotalVotes,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStatistics
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalAcceptedAnswers,
    U.TotalVotes,
    U.TotalScore,
    TH.Name AS TagName,
    PT.Name AS PostTypeName,
    COALESCE(PH.CreationDate, 'N/A') AS LastActiveDate,
    CASE 
        WHEN U.TotalScore >= 1000 THEN 'Gold'
        WHEN U.TotalScore >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS Badge
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    PostHistoryTypes TH ON PH.PostHistoryTypeId = TH.Id
WHERE 
    U.ScoreRank <= 10
ORDER BY 
    U.TotalScore DESC;
