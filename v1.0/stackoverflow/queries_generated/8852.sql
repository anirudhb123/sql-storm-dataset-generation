WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        COUNT(DISTINCT B.Id) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopEngagedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostsCreated, 
        UpvotesReceived, 
        DownvotesReceived, 
        CommentsMade, 
        BadgesEarned,
        RANK() OVER (ORDER BY PostsCreated DESC, UpvotesReceived DESC) AS EngagementRank
    FROM 
        UserEngagement
)

SELECT 
    UserId, 
    DisplayName, 
    PostsCreated, 
    UpvotesReceived, 
    DownvotesReceived, 
    CommentsMade, 
    BadgesEarned
FROM 
    TopEngagedUsers
WHERE 
    EngagementRank <= 10
ORDER BY 
    EngagementRank;
