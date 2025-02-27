-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.Tags,
        PT.Name AS PostType
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        PostStatistics
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.TotalBadges,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViews
FROM 
    UserActivity UA
LEFT JOIN 
    TopPosts TP ON UA.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE 
    UA.TotalPosts > 0
ORDER BY 
    UA.TotalPosts DESC, UA.TotalUpVotes DESC
LIMIT 100;
