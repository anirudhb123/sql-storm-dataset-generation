WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        MAX(P.CreationDate) AS MostRecentActivity
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
),
RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
)

SELECT 
    U.DisplayName,
    P.Title,
    P.Body,
    US.TotalVotes,
    US.UpVotes,
    US.DownVotes,
    PS.CommentCount,
    PS.CloseReopenCount,
    PS.MostRecentActivity,
    COALESCE(NULLIF(P.Tags, ''), 'No Tags') AS TagsInfo,
    R.ReputationRank
FROM Posts P
JOIN UserVoteStats US ON P.OwnerUserId = US.UserId
JOIN PostStats PS ON P.Id = PS.PostId
JOIN RankedUsers R ON P.OwnerUserId = R.UserId
WHERE P.ViewCount > 100
AND PS.CommentCount > 5
AND (
    EXISTS (
        SELECT 1 
        FROM Votes V 
        WHERE V.PostId = P.Id AND V.VoteTypeId = 2
    ) 
    OR P.AcceptedAnswerId IS NOT NULL
)
ORDER BY US.TotalVotes DESC, P.CreationDate DESC
LIMIT 50;
