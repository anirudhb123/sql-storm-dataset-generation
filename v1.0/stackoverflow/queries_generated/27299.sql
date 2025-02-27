WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE(COUNT(DISTINCT PL.RelatedPostId), 0) AS RelatedPostCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on recent posts
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.ViewCount
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.ViewCount) AS AvgViewsPerPost,
        SUM(P.CommentCount) AS TotalComments,
        SUM(P.UpVoteCount) AS TotalUpVotes,
        SUM(P.DownVoteCount) AS TotalDownVotes,
        MAX(P.Title) AS MostPopularPostTitle  -- Assuming the last entry is the highest viewed
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        PostMetrics PM ON P.Id = PM.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostsCreated,
    U.TotalViews,
    U.AvgViewsPerPost,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    UB.BadgeCount,
    UB.BadgeNames,
    UB.LastBadgeDate,
    U.MostPopularPostTitle
FROM 
    UserPostStats U
JOIN 
    UserBadges UB ON U.UserId = UB.UserId
ORDER BY 
    U.TotalViews DESC
LIMIT 10;  -- Return the top 10 users by total views
