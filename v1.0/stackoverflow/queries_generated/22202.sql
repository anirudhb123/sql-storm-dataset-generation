WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentsCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate AS ChangeDate,
        PH.Comment AS ChangeComment
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
),
ClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        PH.ChangeDate,
        PH.ChangeComment,
        PH.PostHistoryTypeId
    FROM 
        Posts P
    JOIN 
        PostHistoryDetails PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
),
AggregatedPostData AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerName,
        RP.ViewCount,
        RP.Rank,
        PC.CommentsCount,
        PC.LastCommentDate,
        CASE 
            WHEN CP.PostId IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostComments PC ON RP.PostId = PC.PostId
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.Id
)
SELECT 
    APD.PostId,
    APD.Title,
    APD.CreationDate,
    APD.OwnerName,
    APD.ViewCount,
    APD.Rank,
    APD.CommentsCount,
    APD.LastCommentDate,
    APD.PostStatus,
    CASE 
        WHEN APD.Rank <= 3 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory,
    CASE 
        WHEN APD.CommentsCount > 10 THEN 'Highly Engaged'
        ELSE 
            CASE 
                WHEN APD.CommentsCount IS NULL THEN 'No Comments'
                ELSE 'Low Engagement'
            END
    END AS EngagementLevel
FROM 
    AggregatedPostData APD
WHERE 
    APD.PostStatus = 'Active'
ORDER BY 
    APD.ViewCount DESC, 
    APD.Rank;

This query primarily evaluates posts from the last 30 days and categorizes them based on their score and engagement using window functions, common table expressions (CTEs), and complex conditions, all while factoring in the status of the posts with respect to comments and closure. Also, it calculates additional engagement metrics while differentiating between active and closed posts with interesting conditions.
