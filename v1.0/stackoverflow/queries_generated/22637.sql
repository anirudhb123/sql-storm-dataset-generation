WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        P.Score,
        COUNT(CM.Id) FILTER (WHERE CM.PostId IS NOT NULL) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.PostId IS NOT NULL AND V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.PostId IS NOT NULL AND V.VoteTypeId = 3) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.LastActivityDate > CURRENT_DATE - INTERVAL '1 month'
    GROUP BY P.Id
),
UserPostExperience AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(P.ViewCount) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
)
SELECT
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    PS.Title AS PostTitle,
    PS.PostId,
    PS.Score AS PostScore,
    PS.UpVoteCount,
    PS.DownVoteCount,
    UPE.PositivePosts,
    UPE.NegativePosts,
    UPE.TotalViews,
    CASE 
        WHEN UR.ReputationRank = 1 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType,
    COALESCE(PS.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN UPE.TotalViews IS NULL OR UPE.TotalViews = 0 THEN 'No Views'
        ELSE CAST(ROUND((CAST(UPE.TotalViews AS FLOAT) / NULLIF(PS.ViewCount, 0)), 2) AS VARCHAR(10))
    END AS ViewToPostRatio,
    pg_catalog.string_agg(DISTINCT T.TagName, ', ') AS Tags
FROM UserRankings UR
LEFT JOIN PostSummary PS ON UR.PostCount > 0
LEFT JOIN UserPostExperience UPE ON UR.UserId = UPE.UserId
LEFT JOIN LATERAL (
    SELECT 
        UNNEST(string_to_array(P.Tags, '><')) AS TagName
    FROM Posts P
    WHERE P.Id = PS.PostId
) AS T ON true
GROUP BY 
    UR.UserId, UR.DisplayName, UR.Reputation, UR.ReputationRank, 
    PS.Title, PS.PostId, PS.Score, 
    UPE.PositivePosts, UPE.NegativePosts, UPE.TotalViews
ORDER BY 
    UR.Reputation DESC, PS.Score DESC
LIMIT 100;
