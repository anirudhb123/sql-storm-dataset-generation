WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostsCount,
        COUNT(C.Id) AS CommentsCount,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPostDate,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TopTags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                T.TagName
            FROM 
                Tags T
            WHERE 
                P.Tags LIKE '%' || T.TagName || '%'
            ORDER BY 
                T.Count DESC
            LIMIT 3
        ) T ON TRUE
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UE.DisplayName,
    UE.TotalPosts,
    UE.QuestionsAsked,
    UE.AnswersGiven,
    UE.TotalComments,
    UE.TotalUpvotes,
    UE.TotalDownvotes,
    PS.PostsCount,
    PS.CommentsCount,
    PS.AverageScore,
    PS.LatestPostDate,
    PS.TopTags
FROM 
    UserEngagement UE
JOIN 
    PostStats PS ON UE.UserId = PS.OwnerUserId
ORDER BY 
    UE.TotalPosts DESC, UE.TotalUpvotes DESC;
