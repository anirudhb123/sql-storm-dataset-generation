WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        P.ParentId,
        1 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        P.ParentId,
        RP.Level + 1
    FROM Posts P
    INNER JOIN RecursivePostHierarchy RP ON P.ParentId = RP.PostId
),
PostVoteSummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes V
    GROUP BY PostId
),
UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes
    FROM Users U
    WHERE U.Reputation > 1000
),
RecentPostInfo AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.CreationDate,
        RP.ViewCount,
        PS.UpVotes,
        PS.DownVotes,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM RecursivePostHierarchy RP
    LEFT JOIN PostVoteSummary PS ON RP.PostId = PS.PostId
    LEFT JOIN Users U ON RP.OwnerUserId = U.Id
    WHERE RP.Level < 3
    AND RP.CreationDate > '2023-01-01'
)

SELECT 
    RPI.Title,
    RPI.Score,
    RPI.ViewCount,
    RPI.OwnerDisplayName,
    RPI.OwnerReputation,
    COALESCE(RPI.UpVotes, 0) AS Upvotes,
    COALESCE(RPI.DownVotes, 0) AS Downvotes,
    RPI.CreationDate,
    ROW_NUMBER() OVER (ORDER BY RPI.Score DESC) AS Rank
FROM RecentPostInfo RPI
LEFT JOIN Badges B ON RPI.OwnerUserId = B.UserId
WHERE B.Class = 1 AND B.Date > RPI.CreationDate - INTERVAL '1 year'
ORDER BY Rank
LIMIT 10;
