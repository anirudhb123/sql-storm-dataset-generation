-- Performance Benchmarking SQL Query

-- This query will return statistics about posts, users, and their interactions
-- The aim is to measure performance across various aspects of the StackOverflow schema

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        U.CreationDate AS OwnerCreationDate
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostSummary AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        AVG(P.CommentCount) AS AvgCommentCount
    FROM 
        PostStats P
    GROUP BY 
        P.PostTypeId
)
SELECT 
    PS.PostTypeId,
    PS.TotalPosts,
    PS.AvgScore,
    PS.TotalViews,
    PS.TotalAnswers,
    PS.AvgCommentCount,
    US.TotalBounty,
    US.BadgeCount,
    US.TotalUpVotes,
    US.TotalDownVotes
FROM 
    PostSummary PS
LEFT JOIN 
    UserStats US ON PS.PostTypeId = US.UserId  -- Adjust based on user-related needs
ORDER BY 
    PS.PostTypeId;
