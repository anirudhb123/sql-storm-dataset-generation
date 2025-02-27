WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        PT.Name AS PostType
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
MostUpvotedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.PostType,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        PostStatistics PS
    LEFT JOIN 
        Votes V ON PS.PostId = V.PostId
    GROUP BY 
        PS.PostId, PS.Title, PS.CreationDate, PS.PostType
    ORDER BY 
        UpvoteCount DESC
    LIMIT 10
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.Upvotes,
    UA.Downvotes,
    UA.TotalBadges,
    MUP.PostId,
    MUP.Title AS MostUpvotedPost,
    MUP.CreationDate AS PostCreationDate,
    MUP.PostType,
    MUP.UpvoteCount
FROM 
    UserActivity UA
JOIN 
    MostUpvotedPosts MUP ON UA.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = MUP.PostId)
ORDER BY 
    UA.TotalPosts DESC, UA.Upvotes DESC;
