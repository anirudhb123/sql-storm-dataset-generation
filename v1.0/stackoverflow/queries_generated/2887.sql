WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgPostScore,
        TotalViews,
        Rank
    FROM 
        UserStats
    WHERE 
        Reputation > 100
), RecentComments AS (
    SELECT 
        C.UserId,
        COUNT(*) AS RecentCommentCount
    FROM 
        Comments C
    WHERE 
        C.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        C.UserId
), UserAchievements AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgesEarned
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AvgPostScore,
    TU.TotalViews,
    COALESCE(RC.RecentCommentCount, 0) AS RecentCommentCount,
    COALESCE(UA.BadgesEarned, 'No badges') AS BadgesEarned
FROM 
    TopUsers TU
LEFT JOIN 
    RecentComments RC ON TU.UserId = RC.UserId
LEFT JOIN 
    UserAchievements UA ON TU.UserId = UA.UserId
ORDER BY 
    TU.Rank ASC, TU.TotalViews DESC
LIMIT 50;

WITH RECURSIVE CloseReasons AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ReasonRank
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- 10=Closed, 11=Reopened
)
SELECT 
    P.Title,
    CR.CloseReason,
    CR.CreationDate
FROM 
    Posts P
LEFT JOIN 
    CloseReasons CR ON P.Id = CR.PostId
WHERE 
    CR.ReasonRank = 1
ORDER BY 
    CR.CreationDate DESC
LIMIT 100;
