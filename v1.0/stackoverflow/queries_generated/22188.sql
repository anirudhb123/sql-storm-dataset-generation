WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        COUNT(P.Id) AS RelatedCount
    FROM 
        PostHistory PH 
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- Indicates post was closed
    GROUP BY 
        PH.PostId, PH.Comment
)

SELECT 
    U.DisplayName AS UserName,
    U.VoteCount,
    U.UpVotes,
    U.DownVotes,
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.Score,
    PP.ViewCount,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(CP.RelatedCount, 0) AS RelatedCount
FROM 
    UserVotes U
JOIN 
    PopularPosts PP ON U.UserId = PP.OwnerPostRank   -- Only include users with posts
LEFT JOIN 
    ClosedPosts CP ON PP.PostId = CP.PostId
WHERE 
    U.VoteRank <= 10  -- Get top 10 users by votes
    AND (U.UpVotes - U.DownVotes) > 5  -- Filter out users with more downvotes than upvotes
ORDER BY 
    U.VoteCount DESC, PP.Score DESC;

-- Additional metrics can be fetched using FULL OUTER JOIN if needed
WITH TotalMetrics AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownVotes,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
)

SELECT 
    TM.UserId,
    TM.TotalUpVotes,
    TM.TotalDownVotes,
    TM.TotalViews,
    TM.TotalComments,
    CASE 
        WHEN TM.TotalUpVotes > 0 THEN 'Positive User'
        WHEN TM.TotalDownVotes > 0 THEN 'Negative User'
        ELSE 'Neutral User'
    END AS UserSentiment
FROM 
    TotalMetrics TM
WHERE 
    (TM.TotalUpVotes + TM.TotalDownVotes) > 0  -- Only include users with votes
ORDER BY 
    TM.TotalViews DESC;
