WITH RankedUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),

PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        MAX(PH.CreationDate) AS LastActivityDate,
        P.ViewCount,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Active' 
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id
),

UserScore AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        AVG(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
)

SELECT 
    U.DisplayName,
    R.PostCount,
    R.UpvotedPosts,
    R.DownvotedPosts,
    R.TotalViews,
    P.CommentCount,
    P.LastActivityDate,
    P.PostStatus,
    S.UpVotesReceived,
    S.DownVotesReceived,
    S.AvgPostScore
FROM 
    RankedUserPosts R
JOIN 
    PostActivity P ON R.UserId = P.OwnerUserId
JOIN 
    UserScore S ON R.UserId = S.UserId
WHERE 
    R.PostCount > 0 
    AND R.TotalViews > 100
    AND (S.UpVotesReceived - S.DownVotesReceived) > 10
ORDER BY 
    R.TotalViews DESC, 
    R.DisplayName ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

This query consists of several CTEs (Common Table Expressions) to compute necessary metrics for users and their posts, while also filtering and ranking users based on their contributions and interactions in the Stack Overflow schema. The output will provide an overview of users who have a notable presence in terms of posts, comments, and votes, sorted by their total views and names.
