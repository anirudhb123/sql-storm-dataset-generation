WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopTags AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id
),
HighScoringPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Score > 10
)

SELECT 
    U.DisplayName,
    SUM(PS.TotalPosts) AS UserTotalPosts,
    SUM(PS.TotalQuestions) AS UserTotalQuestions,
    SUM(PS.TotalAnswers) AS UserTotalAnswers,
    COUNT(DISTINCT TS.TagId) AS UniqueTagsContributed,
    AVG(HSP.Score) AS AvgHighScoringPostScore,
    COALESCE(SUM(HS.Score), 0) AS TotalHighScoringPostScore
FROM 
    UserPostStats PS
LEFT JOIN 
    TopTags TS ON TS.PostCount > 5
LEFT JOIN 
    HighScoringPosts HSP ON PS.UserId = HSP.OwnerUserId
WHERE 
    PS.TotalPosts > 0
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(DISTINCT HSP.PostId) > 0
ORDER BY 
    UserTotalPosts DESC, UserTotalQuestions DESC;
