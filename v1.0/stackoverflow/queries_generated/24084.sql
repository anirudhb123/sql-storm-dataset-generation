WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 8 THEN V.BountyAmount ELSE 0 END) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(V.BountyAmount) DESC) AS BountyRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        P.CreationDate,
        DENSE_RANK() OVER (ORDER BY P.CreationDate DESC) AS RecentPostRank,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON T.ExcerptPostId = P.Id
    GROUP BY 
        P.Id, P.Title, P.Score, P.AnswerCount, P.CommentCount, P.FavoriteCount, P.CreationDate
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END) AS LastReopenedDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId 
)
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.Score,
    PE.AnswerCount,
    PE.CommentCount,
    PE.FavoriteCount,
    PE.Tags,
    COALESCE(CPH.CloseCount, 0) AS CloseCount,
    COALESCE(CPH.LastClosedDate, 'Never Closed') AS LastClosed,
    COALESCE(CPH.LastReopenedDate, 'Never Reopened') AS LastReopened,
    UV.UpvoteCount,
    UV.DownvoteCount,
    UV.TotalBounty
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    PostEngagement PE ON P.Id = PE.PostId
LEFT JOIN 
    ClosedPostHistory CPH ON P.Id = CPH.PostId
LEFT JOIN 
    UserVoteStats UV ON U.Id = UV.UserId
WHERE 
    P.Score > 0
    AND UV.UpvoteCount - UV.DownvoteCount > 10
    AND PE.RecentPostRank <= 100
ORDER BY 
    P.CreationDate DESC, UV.TotalBounty DESC;
