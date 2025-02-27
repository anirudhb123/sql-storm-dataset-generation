WITH UserWithBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.Comment,
        PH.CreationDate,
        P.Title,
        P.OwnerUserId,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentHistoryRank
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
CommentsAggregate AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(RPH.Comment, 'No recent history') AS RecentComment,
    T.Title AS TopPostTitle,
    T.Score AS TopPostScore,
    COALESCE(CA.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN T.PostRank = 1 THEN 'Top'
        WHEN T.PostRank IS NULL THEN 'No posts'
        ELSE 'Other'
    END AS PostStatus,
    CASE 
        WHEN UB.LastBadgeDate IS NULL THEN 'No badges earned'
        ELSE CONCAT('Last badge on ', TO_CHAR(UB.LastBadgeDate, 'YYYY-MM-DD HH24:MI:SS'))
    END AS BadgeInfo
FROM 
    UserWithBadges UB
LEFT JOIN 
    TopPosts T ON UB.UserId = T.OwnerUserId AND T.PostRank = 1
LEFT JOIN 
    RecentPostHistory RPH ON T.Id = RPH.PostId AND RPH.RecentHistoryRank = 1
LEFT JOIN 
    CommentsAggregate CA ON T.Id = CA.PostId
WHERE 
    (UB.BadgeCount IS NULL OR UB.BadgeCount > 0) 
    AND (T.Score IS NULL OR T.Score > 0)
ORDER BY 
    UB.BadgeCount DESC, 
    T.Score DESC NULLS LAST;
