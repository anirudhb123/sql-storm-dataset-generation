WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation < 100 THEN 'Newbie'
            WHEN U.Reputation BETWEEN 100 AND 999 THEN 'Contributor'
            WHEN U.Reputation BETWEEN 1000 AND 4999 THEN 'Experienced'
            ELSE 'Expert' 
        END AS ReputationCategory
    FROM Users U
),
DailyVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId BETWEEN 6 AND 8 THEN V.BountyAmount ELSE 0 END) AS Bounties
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY P.Id
),
ClosePostReasons AS (
    SELECT 
        PH.PostId,
        JSON_AGG(DISTINCT CR.Name) AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON CR.Id::text = PH.Comment
    WHERE PH.PostHistoryTypeId = 10 -- Closed Posts
    GROUP BY PH.PostId
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.PostId) AS CommentCount,
        SUM(CASE WHEN C.CreationDate >= CURRENT_DATE - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentComments
    FROM Users U
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
)
SELECT 
    U.DisplayName AS User_DisplayName,
    UR.ReputationCategory AS User_ReputationCategory,
    D.PostId,
    D.TotalVotes,
    COALESCE(D.UpVotes, 0) AS UpVotes,
    COALESCE(D.DownVotes, 0) AS DownVotes,
    COALESCE(D.Bounties, 0) AS TotalBounties,
    COALESCE(CPR.CloseReasons, 'No reasons') AS ReasonsForClosure,
    MA.CommentCount,
    MA.RecentComments
FROM UserReputation UR
JOIN Users U ON U.Id = UR.UserId
LEFT JOIN DailyVotes D ON D.PostId IN 
    (SELECT P.Id 
     FROM Posts P 
     WHERE P.OwnerUserId = U.Id)
LEFT JOIN ClosePostReasons CPR ON D.PostId = CPR.PostId
LEFT JOIN MostActiveUsers MA ON U.Id = MA.UserId
WHERE U.Location IS NOT NULL
AND U.Reputation > 0
ORDER BY UR.ReputationCategory DESC, D.TotalVotes DESC
LIMIT 100;
