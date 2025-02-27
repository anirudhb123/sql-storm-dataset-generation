WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
),
UserWithPosts AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.PostCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalViews
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
)
SELECT 
    UWP.UserId,
    UWP.DisplayName,
    UWP.Reputation,
    COALESCE(UWP.PostCount, 0) AS TotalPosts,
    COALESCE(UWP.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UWP.DownVotes, 0) AS TotalDownVotes,
    UWP.TotalViews,
    (UWP.UpVotes - UWP.DownVotes) AS NetVotes,
    CASE 
        WHEN UWP.Reputation >= 1000 THEN 'High Reputation'
        WHEN UWP.Reputation >= 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserWithPosts UWP
WHERE UWP.TotalViews >= 1000
AND UWP.ReputationRank <= 50
ORDER BY UWP.Reputation DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
