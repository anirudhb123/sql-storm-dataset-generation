WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN 1 ELSE 0 END), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END), 0) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(P.Score), 0) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, TotalPosts, QuestionsCount, AnswersCount, TotalScore
    FROM 
        UserStatistics
    WHERE 
        UserRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score AS PostScore,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(CM.Id), 0) AS CommentCount,
        PT.Name AS PostTypeName
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName, P.Score, PT.Name
),
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.ViewCount,
        PD.CreationDate,
        PD.PostScore,
        PD.PostTypeName,
        RANK() OVER (ORDER BY PD.ViewCount DESC, PD.PostScore DESC) AS PopularityRank
    FROM 
        PostDetails PD
)
SELECT 
    T.DisplayName AS TopUser,
    T.Reputation AS UserReputation,
    T.QuestionsCount AS UserQuestions,
    T.AnswersCount AS UserAnswers,
    P.Title AS PopularPost,
    P.OwnerDisplayName,
    P.ViewCount,
    P.CreationDate,
    P.PostTypeName,
    CASE 
        WHEN P.PostScore > 0 THEN 'Positive' 
        ELSE 'Neutral or Negative' 
    END AS PostScoreStatus,
    CASE 
        WHEN P.CreationDate IS NULL THEN 'Not available' 
        ELSE to_char(P.CreationDate, 'YYYY-MM-DD HH24:MI:SS') 
    END AS FormattedCreationDate
FROM 
    TopUsers T
JOIN 
    PopularPosts P ON T.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId IN (1, 2))
WHERE 
    P.PopularityRank <= 5
ORDER BY 
    T.Reputation DESC, P.ViewCount DESC;
