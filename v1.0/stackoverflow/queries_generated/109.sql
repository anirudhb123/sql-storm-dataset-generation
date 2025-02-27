WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        T.TagName,
        COALESCE(CR.Name, 'Not Closed') AS CloseReason
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE CONCAT('%,', T.TagName, ',%')
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes CR ON PH.Comment::int = CR.Id
),
PostsWithComments AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.CreationDate,
        PD.TagName,
        COUNT(C.Id) AS CommentCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        Comments C ON PD.PostId = C.PostId
    GROUP BY 
        PD.PostId, PD.Title, PD.Score, PD.ViewCount, PD.CreationDate, PD.TagName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.Reputation,
        UA.TotalPosts,
        UA.TotalViews,
        UA.Upvotes,
        UA.Downvotes,
        RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity UA
    WHERE 
        UA.TotalPosts > 0
)
SELECT 
    U.DisplayName,
    U.Reputation,
    PU.Title,
    PU.Score,
    PU.CommentCount,
    PU.CloseReason,
    ROW_NUMBER() OVER (PARTITION BY PU.TagName ORDER BY PU.ViewCount DESC) AS RankedPostsByTag
FROM 
    TopUsers U
JOIN 
    PostsWithComments PU ON U.UserId = PU.PostId
WHERE 
    U.Reputation > 1000
    AND PU.CloseReason != 'Not Closed'
    AND PU.CommentCount > 5
ORDER BY 
    U.Reputation DESC, PU.Score DESC, PU.ViewCount DESC;
