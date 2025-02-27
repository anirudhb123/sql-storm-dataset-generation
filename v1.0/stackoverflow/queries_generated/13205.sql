-- Performance Benchmarking Query
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        PT.Name AS PostType,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        AVG(VoteTypeId) AS AvgVoteType
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, PT.Name
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    P.Title AS PostTitle,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.TotalVotes,
    P.AvgVoteType
FROM 
    UserEngagement U
LEFT JOIN 
    PostStatistics P ON P.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.UserId)
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
