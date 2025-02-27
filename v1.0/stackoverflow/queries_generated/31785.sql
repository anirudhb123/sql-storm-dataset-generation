WITH RecursivePosts AS (
    SELECT P.Id AS PostId, P.Title, P.OwnerUserId, P.CreationDate, P.ParentId, 
           CAST(0 AS int) AS Depth
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT P.Id AS PostId, P.Title, P.OwnerUserId, P.CreationDate, P.ParentId, 
           RP.Depth + 1
    FROM Posts P
    JOIN RecursivePosts RP ON P.ParentId = RP.PostId
),
UserVotes AS (
    SELECT V.UserId, 
           COUNT(CASE WHEN VT.Name = 'UpMod' THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN VT.Name = 'DownMod' THEN 1 END) AS DownVotes,
           COUNT(DISTINCT V.PostId) AS PostVotes
    FROM Votes V
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id 
    GROUP BY V.UserId
),
RankedPosts AS (
    SELECT RP.PostId, RP.Title, RP.OwnerUserId, RP.CreationDate, RP.Depth,
           U.Reputation AS UserReputation,
           ROW_NUMBER() OVER (PARTITION BY RP.OwnerUserId ORDER BY RP.CreationDate DESC) AS RecentPostRank
    FROM RecursivePosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
),
VoteStats AS (
    SELECT UP.UserId,
           AVG(UpVotes) AS AverageUpVotes,
           AVG(DownVotes) AS AverageDownVotes,
           AVG(PostVotes) AS AveragePostVotes
    FROM UserVotes UP
    GROUP BY UP.UserId
),
FinalOutput AS (
    SELECT RP.PostId, RP.Title, RP.CreationDate, 
           RP.Depth, RP.UserReputation,
           VS.AverageUpVotes, VS.AverageDownVotes, VS.AveragePostVotes
    FROM RankedPosts RP
    LEFT JOIN VoteStats VS ON RP.OwnerUserId = VS.UserId
)
SELECT FO.PostId, FO.Title, FO.CreationDate, FO.Depth, FO.UserReputation, 
       COALESCE(FO.AverageUpVotes, 0) AS UpVotesAverage, 
       COALESCE(FO.AverageDownVotes, 0) AS DownVotesAverage, 
       COALESCE(FO.AveragePostVotes, 0) AS TotalVotesAverage
FROM FinalOutput FO
WHERE FO.Depth <= 2
ORDER BY FO.Depth, FO.CreationDate DESC;
