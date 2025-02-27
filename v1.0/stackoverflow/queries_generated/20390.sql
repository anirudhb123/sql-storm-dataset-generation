WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS AverageViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.Score) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
PostHistoryAnalysis AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        MIN(PH.CreationDate) AS FirstEdit,
        MAX(PH.CreationDate) AS LastEdit,
        ARRAY_AGG(DISTINCT PHT.Name) AS EditTypes,
        COUNT(DISTINCT CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.Id END) AS CloseVotes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId, PH.PostId
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.AnswerCount IS NOT NULL THEN P.AnswerCount ELSE 0 END) AS TotalAnswers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10 -- Only consider tags with more than 10 occurrences
),
ComprehensiveStats AS (
    SELECT 
        US.UserId,
        US.Reputation,
        US.TotalPosts,
        US.TotalScore,
        US.AverageViews,
        PHA.HistoryCount,
        PHA.FirstEdit,
        PHA.LastEdit,
        PHT.EditTypes,
        PT.TagName,
        PT.PostCount,
        PT.TotalAnswers,
        COALESCE(US.Reputation / NULLIF(US.TotalPosts, 0), 0) AS ReputationPerPost
    FROM 
        UserStats US
    LEFT JOIN 
        PostHistoryAnalysis PHA ON US.UserId = PHA.UserId
    LEFT JOIN 
        PopularTags PT ON PT.PostCount > 0
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    TotalScore,
    AverageViews,
    HistoryCount,
    FirstEdit,
    LastEdit,
    unnest(EditTypes) AS EditType,
    TagName,
    PostCount,
    TotalAnswers,
    ReputationPerPost
FROM 
    ComprehensiveStats
WHERE 
    Reputation < 5000 AND HistoryCount >= 5
ORDER BY 
    Reputation DESC, TotalScore DESC; 
