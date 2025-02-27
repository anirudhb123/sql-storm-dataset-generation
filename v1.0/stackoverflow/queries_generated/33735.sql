WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        NULL::int AS ParentUserId,
        1 AS Level
    FROM Users U
    WHERE U.Reputation > 1000 -- Start with users having more than 1000 reputation

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        UR.UserId,
        UR.Level + 1
    FROM Users U
    JOIN Posts P ON P.OwnerUserId = U.Id
    JOIN UserReputation UR ON UR.UserId = P.OwnerUserId
    WHERE U.Reputation > 1000 AND UR.Level < 4 -- Limit depth to 4 levels
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        COALESCE(UP.UserId, -1) AS MostUpVotedUserId -- Assign -1 if no upvotes exist
    FROM Posts P
    LEFT JOIN (
        SELECT 
            V.PostId,
            V.UserId,
            COUNT(*) AS UpVoteCount
        FROM Votes V
        WHERE V.VoteTypeId = 2 -- Count only upvotes
        GROUP BY V.PostId, V.UserId
    ) UP ON UP.PostId = P.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS TotalComments,
        AVG(C.Score) AS AvgCommentScore
    FROM Comments C
    WHERE C.CreationDate >= NOW() - INTERVAL '30 days' -- Only recently created comments
    GROUP BY C.PostId
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(R.TotalComments, 0) AS RecentCommentCount,
        COALESCE(R.AvgCommentScore, 0) AS AvgCommentScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM UserReputation U
    JOIN PostStats P ON P.MostUpVotedUserId = U.UserId OR P.ViewCount >= 1000
    LEFT JOIN RecentComments R ON R.PostId = P.PostId
)
SELECT 
    DisplayName,
    Reputation,
    COUNT(Title) AS PostsCount,
    SUM(ViewCount) AS TotalViews,
    SUM(Score) AS TotalScore,
    AVG(RecentCommentCount) AS AverageRecentComments,
    STRING_AGG(CONCAT(Title, ' (View: ', ViewCount, ')'), '; ') AS PostDetails
FROM FinalReport
GROUP BY DisplayName, Reputation
HAVING AVG(RecentCommentCount) > 0 -- Show only users with recent comments
ORDER BY TotalViews DESC, TotalScore DESC;
