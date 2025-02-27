-- Performance benchmarking query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(US.PostCount, 0) AS PostCount,
    COALESCE(US.CommentCount, 0) AS CommentCount,
    COALESCE(US.BadgeCount, 0) AS BadgeCount,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.AvgViewCount, 0) AS AvgViewCount,
    COALESCE(PS.QuestionCount, 0) AS QuestionCount,
    COALESCE(PS.AnswerCount, 0) AS AnswerCount
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY 
    U.Reputation DESC;
