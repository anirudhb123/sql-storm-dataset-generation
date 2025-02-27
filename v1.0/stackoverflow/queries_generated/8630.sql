WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS TotalBadges
    FROM Users U
),
TopContributors AS (
    SELECT 
        UserId, DisplayName, Reputation, ReputationRank, CreationDate, LastAccessDate, Views, UpVotes, DownVotes, TotalPosts, TotalBadges
    FROM RankedUsers
    WHERE ReputationRank <= 100
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostActivity AS (
    SELECT 
        AP.PostId,
        AP.Title,
        AP.ViewCount,
        AP.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM ActivePosts AP
    LEFT JOIN Comments C ON AP.PostId = C.PostId
    LEFT JOIN Votes V ON AP.PostId = V.PostId
    GROUP BY AP.PostId, AP.Title, AP.ViewCount, AP.Score
)
SELECT 
    TC.UserId,
    TC.DisplayName,
    TC.Reputation,
    PA.PostId,
    PA.Title,
    PA.ViewCount,
    PA.Score,
    PA.CommentCount,
    PA.VoteCount,
    PA.UpVoteCount,
    PA.DownVoteCount
FROM TopContributors TC
JOIN PostActivity PA ON TC.UserId = PA.OwnerUserId
ORDER BY TC.Reputation DESC, PA.Score DESC
LIMIT 50;
