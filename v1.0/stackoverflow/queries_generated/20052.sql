WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),

UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),

FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.UpVoteCount,
        RP.DownVoteCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    WHERE 
        RP.RankByScore <= 10
        AND RP.UpVoteCount > RP.DownVoteCount
),

RecentClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        P.Title,
        PH.Comment
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
        AND PH.CreationDate >= NOW() - INTERVAL '2 weeks'
)

SELECT 
    FP.Title,
    FP.Score,
    FP.UpVoteCount,
    FP.DownVoteCount,
    FP.OwnerDisplayName,
    COALESCE(RCP.CreationDate, 'No Recent Close Record') AS LastClosedDate,
    COALESCE(RCP.Comment, 'N/A') AS ClosureReason,
    COALESCE(UE.CommentCount, 0) AS UserCommentCount,
    COALESCE(UE.BadgeCount, 0) AS UserBadgeCount,
    UE.TotalViewCount AS UserTotalViewCount
FROM 
    FilteredPosts FP
LEFT JOIN 
    RecentClosedPosts RCP ON FP.PostId = RCP.PostId
LEFT JOIN 
    UserEngagement UE ON FP.OwnerUserId = UE.UserId
ORDER BY 
    FP.Score DESC, FP.Title
LIMIT 50;
