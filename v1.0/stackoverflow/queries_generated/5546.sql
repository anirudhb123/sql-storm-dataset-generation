WITH TagUsage AS (
    SELECT 
        TRIM(SPLIT_PART(Tags, '>', 2)) AS Tag, 
        COUNT(*) AS PostCount 
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        TRIM(SPLIT_PART(Tags, '>', 2)
    HAVING 
        COUNT(*) > 10  -- Only tags with more than 10 usages
),
UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        U.Id, U.DisplayName
),
TagPerformance AS (
    SELECT 
        T.Tag, 
        U.UserId, 
        U.DisplayName,
        SUM(UA.QuestionCount) AS TotalQuestions,
        SUM(UA.TotalScore) AS TotalScore
    FROM 
        TagUsage T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.Tag || '%'
    JOIN 
        UserActivity UA ON UA.QuestionCount > 0
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.Tag, U.UserId, U.DisplayName
)
SELECT 
    TP.Tag, 
    COUNT(DISTINCT TP.UserId) AS UniqueUsers, 
    SUM(TP.TotalScore) AS TotalScore, 
    SUM(TP.TotalQuestions) AS TotalQuestions
FROM 
    TagPerformance TP
GROUP BY 
    TP.Tag
ORDER BY 
    TotalScore DESC, 
    UniqueUsers DESC;
