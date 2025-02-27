WITH RecursiveUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.ViewCount * P.Score AS EngagementScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.ViewCount * P.Score AS EngagementScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        C.UserId = U.Id
        AND P.PostTypeId = 2 -- Answers
), 

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2022-01-01' AND P.CreationDate < CURRENT_TIMESTAMP
), 

PostArchives AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS HistoryType,
        PH.Comment,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRow
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
)

SELECT 
    RUP.UserId,
    RUP.DisplayName,
    COUNT(DISTINCT RUP.PostId) AS TotalQuestions,
    SUM(RUP.EngagementScore) AS TotalEngagement,
    COUNT(DISTINCT P.Id) AS TotalAnswers,
    COUNT(DISTINCT CASE WHEN P.IsAcceptedAnswer = 1 THEN P.PostId END) AS AcceptedAnswers,
    COALESCE(SUM(PD.ViewCount), 0) AS TotalViews,
    COUNT(DISTINCT PA.PostId) AS PostHistoryCount,
    COUNT(DISTINCT CASE WHEN PA.HistoryType = 'Post Closed' THEN PA.PostId END) AS ClosedPosts
FROM 
    RecursiveUserPosts RUP
LEFT JOIN 
    PostDetails P ON RUP.PostId = P.PostId
LEFT JOIN 
    PostArchives PA ON RUP.PostId = PA.PostId
GROUP BY 
    RUP.UserId,
    RUP.DisplayName
HAVING 
    COUNT(DISTINCT RUP.PostId) > 0
ORDER BY 
    TotalEngagement DESC, 
    TotalQuestions DESC;
