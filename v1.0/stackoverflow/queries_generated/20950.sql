WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(B.Reputation), 0) AS TotalBadgesReputation
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostClosure AS (
    SELECT 
        PC.PostId,
        COUNT(PC.PostId) AS ClosedCount,
        STRING_AGG(DISTINCT P.Title, ', ') AS ClosedPostTitles
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        PostClosure PC ON P.Id = PC.PostId
    WHERE 
        PH.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year' 
        AND PHT.Name = 'Post Closed'
    GROUP BY 
        PC.PostId
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Owner,
        PC.ClosedCount,
        PC.ClosedPostTitles,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        UserStats U ON P.OwnerUserId = U.UserId
    LEFT JOIN 
        PostClosure PC ON P.Id = PC.PostId
)

SELECT 
    U.DisplayName,
    U.UpVoteCount AS TotalUpVotes,
    U.DownVoteCount AS TotalDownVotes,
    SUM(CASE WHEN CP.OwnerPostRank = 1 THEN CP.ClosedCount ELSE 0 END) AS MostRecentClosedPostsCount,
    STRING_AGG(DISTINCT CP.Title, '; ') AS RecentlyClosedPostTitles,
    COUNT(DISTINCT CP.PostId) AS TotalClosedPosts,
    COUNT(DISTINCT B.Id) AS BadgesCount
FROM 
    UserStats U
LEFT JOIN 
    ClosedPosts CP ON U.UserId = CP.OwnerUserId
LEFT JOIN 
    Badges B ON U.UserId = B.UserId
GROUP BY 
    U.UserId
HAVING 
    SUM(U.TotalViewCount) > 100
    AND COUNT(DISTINCT B.Id) > 0
ORDER BY 
    U.UpVoteCount DESC, U.Reputation DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
