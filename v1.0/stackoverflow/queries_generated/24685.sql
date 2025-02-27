WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostRanked AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS RankScore,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS CommentCount
    FROM 
        Posts P
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
UserDetails AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.DisplayName,
        U.Views,
        CASE WHEN U.LastAccessDate < NOW() - INTERVAL '1 year' THEN 'Inactive' ELSE 'Active' END AS UserStatus
    FROM 
        Users U
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UserStatus,
    PS.Title AS PostTitle,
    PS.Score AS PostScore,
    COALESCE(CP.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
    COALESCE(PS.CommentCount, 0) AS PostCommentCount,
    COALESCE(US.PostCount, 0) AS TotalPosts,
    US.UpVotesCount - US.DownVotesCount AS NetVotes,
    US.BadgeCount
FROM 
    UserDetails U
LEFT JOIN 
    UserStats US ON U.UserId = US.UserId
LEFT JOIN 
    PostRanked PS ON PS.RankScore <= 5
LEFT JOIN 
    ClosedPosts CP ON PS.Id = CP.PostId
WHERE 
    (US.BadgeCount > 0 OR US.UpVotesCount > 10) 
    AND (U.Reputation > 1000 OR U.Views > 100)
ORDER BY 
    U.Reputation DESC, 
    US.NetVotes DESC
LIMIT 50;

-- Notes: 
-- This query contains multiple CTEs to gather data about users, their votes, badges, and the ranking of posts. 
-- It combines various SQL constructs, including outer joins, aggregates, window functions, and correlated subqueries. 
-- The final selection fetches detailed user performance alongside their post activity, factoring in the closure of posts and applying complex conditions for filtering.
