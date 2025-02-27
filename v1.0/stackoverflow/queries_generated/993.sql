WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
TopPostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
),
FilteredUserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        M.PostCount,
        M.TotalBounties,
        M.UpVotes,
        M.DownVotes,
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount
    FROM UserMetrics M
    INNER JOIN Users U ON M.UserId = U.Id
    LEFT JOIN TopPostStats PS ON U.Id = PS.PostId AND PS.PostRank <= 3
    WHERE M.Reputation > 500
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalBounties,
    COALESCE(UP.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(DW.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(PS.Title, 'No Post') AS TopPostTitle,
    COALESCE(PS.CreationDate, 'N/A') AS TopPostCreationDate
FROM FilteredUserMetrics U
FULL OUTER JOIN TopPostStats PS ON U.UserId = PS.PostId
ORDER BY U.Reputation DESC, U.PostCount DESC
LIMIT 100;
