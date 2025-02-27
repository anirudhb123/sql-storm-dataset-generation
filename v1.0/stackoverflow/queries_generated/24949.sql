WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        MAX(B.Date) AS LatestBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum,
        CASE 
            WHEN P.LastActivityDate < NOW() - INTERVAL '30 days' THEN 'Inactive'
            ELSE 'Active'
        END AS ActivityStatus
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.LastActivityDate
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        PH.CreationDate AS ClosedDate,
        PH.Comment AS CloseReason,
        P.Title
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.UpVoteCount,
    UA.DownVoteCount,
    UA.PostCount,
    UA.CommentCount,
    CASE 
        WHEN UA.LatestBadgeDate IS NOT NULL THEN 
            CONCAT('Last badge received on ', TO_CHAR(UA.LatestBadgeDate, 'YYYY-MM-DD'))
        ELSE 
            'No badges awarded'
    END AS BadgeInfo,
    PM.PostId,
    PM.Title AS PostTitle,
    PM.ViewCount,
    PM.CommentCount AS PostCommentCount,
    PM.BadgeCount AS PostBadgeCount,
    PM.ActivityStatus,
    CP.ClosedPostId,
    CP.ClosedDate,
    CP.CloseReason
FROM 
    UserActivity UA
LEFT JOIN 
    PostMetrics PM ON UA.UserId = PM.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON PM.PostId = CP.ClosedPostId
WHERE 
    UA.Reputation > 0 
ORDER BY 
    UA.Reputation DESC, 
    PM.ViewCount DESC
LIMIT 100;
