WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
), 
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
), 
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ClosureRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    UVs.UpVotes,
    UVs.DownVotes,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(RP.ViewCount, 0) AS RecentPostViewCount,
    COALESCE(RP.Score, 0) AS RecentPostScore,
    COUNT(DISTINCT CPH.PostId) AS ClosedPostsCount,
    MAX(CPH.CreationDate) AS LastClosedPostDate
FROM 
    Users U
LEFT JOIN 
    UserVoteStats UVs ON U.Id = UVs.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentRank = 1
LEFT JOIN 
    ClosedPostHistory CPH ON U.Id = CPH.UserDisplayName AND CPH.ClosureRank = 1
WHERE 
    U.Reputation > 100
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, UVs.UpVotes, UVs.DownVotes, RP.Title, RP.ViewCount, RP.Score
ORDER BY 
    U.Reputation DESC, ClosedPostsCount DESC;
