WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        MAX(U.CreationDate) AS AccountCreated,
        MIN(COALESCE(P.CreationDate, U.CreationDate)) AS FirstActivity
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags,
        COALESCE(PH.ClosedDate, P.LastActivityDate) AS LastActionDate,
        PH.PostHistoryTypeId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(P.Tags, '><')) AS T(TagName) ON TRUE
    GROUP BY 
        P.Id, PH.ClosedDate, P.LastActivityDate, PH.PostHistoryTypeId
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.UpvotedPosts,
        UA.DownvotedPosts,
        UA.TotalBounties,
        P.Tags
    FROM 
        UserActivity UA
    JOIN 
        Posts P ON UA.UserId = P.OwnerUserId
    WHERE 
        UA.TotalPosts > 10 AND (UA.UpvotedPosts + UA.TotalBounties) > UA.DownvotedPosts
    ORDER BY 
        UA.TotalPosts DESC
    LIMIT 5
)

SELECT 
    U.UserId,
    U.DisplayName,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.Tags,
    CASE 
        WHEN PS.PostHistoryTypeId IS NULL THEN 'Active'
        WHEN PS.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN PS.PostHistoryTypeId IN (12, 13) THEN 'Deleted'
        ELSE 'Reviewed'
    END AS PostStatus,
    U.FirstActivity,
    U.AccountCreated
FROM 
    TopUsers U
JOIN 
    PostStats PS ON U.UserId = PS.OwnerUserId
WHERE 
    PS.LastActionDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    U.TotalPosts DESC, PS.ViewCount DESC
LIMIT 50;

-- This query aggregates various user activities in the context of post engagement,
-- leveraging CTEs to encapsulate user activity, post stats and filtering for top users.
-- It employs outer joins for inclusivity, null logic, correlated subqueries, window functions for rank,
-- and it accounts for both closed and active posts while providing a semantically rich user interaction analysis.
