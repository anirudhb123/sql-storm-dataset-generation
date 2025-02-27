WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2)::int, 0) AS UpVoteCount,
        AVG(COALESCE(T.Length, 0)) AS AvgTagLength
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    LEFT JOIN 
        (SELECT 
             P.Id, 
             string_to_array(P.Tags, ',') AS TagsArray
         FROM 
             Posts P) T ON P.Id = T.Id
    GROUP BY 
        P.Id, P.Title, P.Score
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        PH.PostId,
        PH.CreationDate AS ClosureDate,
        RCT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes RCT ON PH.Comment::int = RCT.Id
),
Ranking AS (
    SELECT 
        UserId,
        RANK() OVER (ORDER BY SUM(Post.Score) DESC) AS UserRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        UserId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    UB.BadgeCount,
    P.Title AS PostTitle,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.AvgTagLength,
    CP.ClosedPostId,
    CP.CloseReason,
    CLOSURE.CreationDate AS ClosureTimestamp,
    (CASE 
        WHEN PS.Score > 0 THEN 'Positive' 
        WHEN PS.Score < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END) AS PostSentiment,
    (CASE 
        WHEN PS.Score IS NULL OR PS.CommentCount = 0 THEN 'Inactive'
        ELSE 'Active'
    END) AS UserActivityStatus
FROM 
    UserBadges UB
LEFT JOIN 
    PostStatistics PS ON UB.UserId = PS.PostId
LEFT JOIN 
    ClosedPosts CP ON PS.PostId = CP.PostId
LEFT JOIN 
    Ranking R ON UB.UserId = R.UserId
WHERE 
    (UB.BadgeCount > 10 OR PS.CommentCount > 5)
    AND (PS.AvgTagLength IS NULL OR PS.AvgTagLength > 10)
ORDER BY 
    R.UserRank, UB.BadgeCount DESC;
