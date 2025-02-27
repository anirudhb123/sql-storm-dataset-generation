WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPostActivities AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        MAX(PH.CreationDate) AS LastActivityDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS Actions
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY PH.UserId, PH.PostId
),
RankedUserStats AS (
    SELECT 
        US.*,
        COALESCE(RPA.Actions, 'No recent activities') AS RecentActions,
        RPA.LastActivityDate
    FROM UserStats US
    LEFT JOIN RecentPostActivities RPA ON US.UserId = RPA.UserId
),
TopUsers AS (
    SELECT 
        RUS.*,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScores
    FROM RankedUserStats RUS
    LEFT JOIN Comments C ON RUS.UserId = C.UserId
    GROUP BY RUS.UserId, RUS.DisplayName, RUS.Reputation, RUS.TotalPosts, RUS.TotalBounties, RUS.UpVotes, RUS.DownVotes, RUS.Rank, RUS.RecentActions, RUS.LastActivityDate
    ORDER BY RUS.Reputation DESC
)
SELECT 
    * 
FROM TopUsers 
WHERE TotalPosts > 5 AND UpVotes > DownVotes 
UNION ALL 
SELECT 
    U.*,
    'Overall Post Count: ' || COUNT(P.Id) AS Stats 
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
WHERE U.Reputation < 100 AND P.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
GROUP BY U.Id
ORDER BY Reputation DESC;
