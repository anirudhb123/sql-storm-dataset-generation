WITH UserReputation AS (
    SELECT Id, Reputation,
           CASE 
               WHEN Reputation IS NULL OR Reputation < 1000 THEN 'Novice'
               WHEN Reputation < 5000 THEN 'Intermediate'
               ELSE 'Expert'
           END AS UserLevel
    FROM Users
),
PostActivity AS (
    SELECT OwnerUserId, 
           COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(ViewCount) AS TotalViews
    FROM Posts
    GROUP BY OwnerUserId
),
RecentVotes AS (
    SELECT PostId, 
           COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(DISTINCT UserId) AS UniqueVoters
    FROM Votes
    WHERE CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY PostId
),
PostHistoryAggregate AS (
    SELECT PostId, 
           ARRAY_AGG(DISTINCT PH.PostHistoryTypeId) AS HistoryTypes,
           COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseActions,
           COUNT(CASE WHEN PH.PostHistoryTypeId = 19 THEN 1 END) AS ProtectActions
    FROM PostHistory PH
    GROUP BY PostId
)
SELECT 
    U.DisplayName,
    U.Location,
    UA.UserLevel,
    PA.QuestionCount,
    PA.AnswerCount,
    COALESCE(RV.UpVotes, 0) AS RecentUpVotes,
    COALESCE(RV.DownVotes, 0) AS RecentDownVotes,
    COALESCE(PA.TotalViews, 0) AS TotalPostViews,
    P.Title,
    PH.HistoryTypes,
    PH.CloseActions,
    PH.ProtectActions
FROM Users U
LEFT JOIN UserReputation UA ON U.Id = UA.Id
LEFT JOIN PostActivity PA ON U.Id = PA.OwnerUserId
LEFT JOIN RecentVotes RV ON PA.QuestionCount > 0 AND RV.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = U.Id
)
LEFT JOIN PostHistoryAggregate PH ON PH.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = U.Id AND PostTypeId = 1 LIMIT 1)
WHERE U.Reputation IS NOT NULL
  AND U.CreationDate < NOW() - INTERVAL '5 years'
  AND U.EmailHash IS NULL -- Users without email
ORDER BY UA.UserLevel DESC, RecentUpVotes DESC
LIMIT 100;
