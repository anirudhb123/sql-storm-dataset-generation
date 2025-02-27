WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 YEAR'
        AND P.Score > 0
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpvotesReceived,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownvotesReceived,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 1000 -- filtering for more reputable users
    GROUP BY 
        U.Id
),
PostHistoryAggregates AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        LISTAGG(PHT.Name, ', ') WITHIN GROUP (ORDER BY PHT.Name) AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '6 MONTH'
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName,
    U.UpvotesReceived,
    U.DownvotesReceived,
    U.CommentsReceived,
    COALESCE(PHA.LastEditDate, 'No Edits') AS LastEdit,
    COALESCE(PHA.EditTypes, 'N/A') AS EditTypes,
    CASE 
        WHEN U.UpvotesReceived > U.DownvotesReceived THEN 'Positive Engagement'
        ELSE 'Mixed or Negative Engagement'
    END AS EngagementStatus
FROM 
    RankedPosts RP
JOIN 
    UserEngagement U ON RP.OwnerUserId = U.UserId
LEFT JOIN 
    PostHistoryAggregates PHA ON RP.PostId = PHA.PostId
WHERE 
    RP.Rank = 1
    AND (U.UpvotesReceived - U.DownvotesReceived) > 10  -- Higher engagement threshold
ORDER BY 
    RP.Score DESC, U.UpvotesReceived DESC
LIMIT 100;

WITH RecursiveComments AS (
    SELECT 
        Id,
        PostId,
        Text,
        CreationDate,
        1 AS Depth
    FROM 
        Comments
    WHERE 
        PostId IN (SELECT PostId FROM RankedPosts)
    UNION ALL
    SELECT 
        C.Id,
        C.PostId,
        C.Text,
        C.CreationDate,
        Depth + 1
    FROM 
        Comments C
    JOIN RecursiveComments RC ON C.PostId = RC.Id
    WHERE 
        RC.Depth < 5  -- Limit recursion to a maximum of 5 comment nestings
)
SELECT 
    RC.Depth,
    COUNT(*) AS CommentCountAtDepth
FROM 
    RecursiveComments RC
GROUP BY 
    RC.Depth;
