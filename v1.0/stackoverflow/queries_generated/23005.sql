WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(ABS(P.ViewCount - LAG(P.ViewCount) OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate)), 0) AS ViewCountDifference,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS Status,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    GROUP BY 
        P.Id
),
RankedPosts AS (
    SELECT 
        PS.*,
        Rank() OVER (PARTITION BY PS.Status ORDER BY PS.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY PS.CommentCount DESC) AS CommentRank
    FROM 
        PostStatistics PS
),
ClosedPostComments AS (
    SELECT 
        PS.Title,
        COUNT(C.CommentId) AS ClosedPostCommentCount,
        COUNT(DISTINCT PS.UserId) AS UserCount
    FROM 
        RankedPosts PS
    LEFT JOIN (
        SELECT 
            C.Id AS CommentId,
            P.OwnerUserId AS UserId
        FROM 
            Comments C
        JOIN 
            Posts P ON C.PostId = P.Id
        WHERE 
            P.ClosedDate IS NOT NULL
    ) C ON C.UserId = PS.OwnerUserId
    WHERE 
        PS.Status = 'Closed'
    GROUP BY 
        PS.Title
)

SELECT 
    U.DisplayName,
    UGC.GoldCount,
    UGC.SilverCount,
    UGC.BronzeCount,
    COUNT(RP.PostId) AS TotalPosts,
    SUM(CASE WHEN RP.Status = 'Closed' THEN 1 ELSE 0 END) AS ClosedPosts,
    SUM(CASE WHEN RP.CommentRank < 5 THEN 1 ELSE 0 END) AS HighCommentRankPosts,
    COALESCE(CP.ClosedPostCommentCount, 0) AS ClosedPostCommentCount,
    COALESCE(CP.UserCount, 0) AS UniqueCommentUsersOnClosedPosts
FROM 
    UserBadgeCounts UGC
JOIN 
    Users U ON U.Id = UGC.UserId
LEFT JOIN 
    RankedPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN 
    ClosedPostComments CP ON CP.Title IN (SELECT Title FROM RankedPosts WHERE Status = 'Closed')
GROUP BY 
    U.DisplayName, UGC.GoldCount, UGC.SilverCount, UGC.BronzeCount, CP.ClosedPostCommentCount, CP.UserCount
HAVING 
    COUNT(RP.PostId) > 10
ORDER BY 
    UGC.GoldCount DESC, UGC.SilverCount DESC, UGC.BronzeCount DESC;
