WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
)

SELECT 
    UR.UserId,
    UR.DisplayName,
    COALESCE(PS.TotalPosts, 0) AS PostsPublished,
    COALESCE(PS.QuestionsCount, 0) AS QuestionsAsked,
    COALESCE(PS.AnswersCount, 0) AS AnswersGiven,
    UR.Reputation,
    CASE 
        WHEN UR.Reputation > 10000 THEN 'Expert'
        WHEN UR.Reputation BETWEEN 5000 AND 10000 THEN 'Pro'
        ELSE 'Newbie'
    END AS UserLevel,
    CASE 
        WHEN PS.TotalViewCount IS NULL THEN 'No Views'
        WHEN PS.TotalViewCount > 0 AND PS.TotalViewCount <= 100 THEN 'Low Engagement'
        WHEN PS.TotalViewCount > 100 AND PS.TotalViewCount <= 1000 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel
FROM UserReputation UR
LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
WHERE UR.Reputation > 1000
ORDER BY UR.Reputation DESC
LIMIT 10;

WITH RecentActivities AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        PH.Comment
    FROM PostHistory PH
    WHERE PH.CreationDate > NOW() - INTERVAL '30 days'
),

PostLinksSummary AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedPostsCount
    FROM PostLinks PL
    GROUP BY PL.PostId
)

SELECT 
    U.DisplayName,
    RANK() OVER (PARTITION BY PL.RelatedPostsCount ORDER BY UR.Reputation DESC) AS EngagementRank,
    SUM(CASE WHEN R.UserId IS NOT NULL THEN 1 ELSE 0 END) AS RecentRevisionsCount
FROM Users U
LEFT JOIN RecentActivities R ON U.Id = R.UserId
LEFT JOIN PostLinksSummary PL ON U.Id = PL.PostId
JOIN PostStats PS ON U.Id = PS.OwnerUserId
GROUP BY U.DisplayName, PL.RelatedPostsCount
HAVING COUNT(PL.PostId) > 0 AND SUM(COALESCE(R.Comment, '') <> '') > 0
ORDER BY EngagementRank;
