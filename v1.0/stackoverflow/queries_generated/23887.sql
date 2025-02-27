WITH UserStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY 
        U.Id
), 
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PT.Name, 'Unknown') AS PostType,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    GROUP BY 
        P.Id, PT.Name
),
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalBounties,
    UV.Upvotes,
    UV.Downvotes,
    U.PostCount,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.PostType,
    P.CommentCount,
    COALESCE(Closed.CloseCount, 0) AS NumberOfClosures,
    CASE 
        WHEN (UV.TotalUpvotes + UV.TotalDownvotes) > 0 
        THEN ROUND((UV.TotalUpvotes * 1.0 / NULLIF(UV.TotalVotes, 0)) * 100, 2) 
        ELSE 0
    END AS UpvotePercentage
FROM 
    UserStats U
LEFT JOIN 
    VoteSummary UV ON UV.UserId = U.Id
LEFT JOIN 
    PostInfo P ON P.OwnerUserId = U.Id
LEFT JOIN 
    ClosedPosts Closed ON Closed.PostId = P.PostId
WHERE 
    U.Reputation > 100
ORDER BY 
    U.Reputation DESC, UpvotePercentage DESC, P.ViewCount DESC;

