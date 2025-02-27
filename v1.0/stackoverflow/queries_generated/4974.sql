WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        PositivePosts, 
        TotalViews,
        DENSE_RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserStats
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        COALESCE(CAST(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS INT), 0) AS CommentCount,
        COALESCE(CAST(SUM(V.VoteTypeId = 2) AS INT), 0) AS UpvoteCount,
        COALESCE(CAST(SUM(V.VoteTypeId = 3) AS INT), 0) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.TotalViews AS UserTotalViews,
    R.PostId,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    R.ViewCount AS RecentPostViews,
    R.CommentCount,
    R.UpvoteCount,
    R.DownvoteCount
FROM 
    TopUsers TU
JOIN 
    RecentPosts R ON R.OwnerName = TU.DisplayName
WHERE 
    TU.RankByViews <= 5
ORDER BY 
    TU.RankByViews, R.CreationDate DESC;
