WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER(PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, GETDATE())
), RecentBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Badges B
    WHERE 
        B.Date >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY 
        B.UserId
), ClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        COUNT(H.Id) AS CloseReasonsCount
    FROM 
        Posts P
    JOIN 
        PostHistory H ON P.Id = H.PostId 
    WHERE 
        H.PostHistoryTypeId = 10
    GROUP BY 
        P.Id, P.Title, P.CreationDate
), UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(RB.BadgeCount, 0) AS BadgeCount,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        RecentBadges RB ON U.Id = RB.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, RB.BadgeCount
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.CreationDate,
    RP.ViewCount,
    RP.OwnerDisplayName,
    UA.UserId,
    UA.DisplayName AS UserDisplayName,
    UA.BadgeCount,
    UA.CommentCount,
    UA.UpVotes,
    UA.DownVotes,
    CP.CloseReasonsCount
FROM 
    RankedPosts RP
JOIN 
    UserActivity UA ON RP.OwnerDisplayName = UA.DisplayName
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.Id
WHERE 
    RP.ScoreRank <= 5
AND 
    UA.BadgeCount > 0
ORDER BY 
    RP.CreationDate DESC, RP.Score DESC;

This SQL query showcases various advanced constructs including Common Table Expressions (CTEs), ranking and window functions, correlated subqueries, multiple joins, filtering with complex predicates, and aggregates. It queries recent posts with scores, user activities, and badges, while also checking for closed posts associated with high-scoring content.
