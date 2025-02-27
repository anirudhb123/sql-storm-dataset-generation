-- Performance Benchmarking Query
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE((SELECT SUM(Score) FROM Votes WHERE PostId = P.Id), 0) AS TotalVoteScore
    FROM 
        Posts P
),
AggregatedStatistics AS (
    SELECT 
        UStats.UserId,
        UStats.DisplayName,
        UStats.PostCount,
        UStats.BadgeCount,
        UStats.TotalBountyAmount,
        SUM(PStats.Score) AS TotalPostScore,
        SUM(PStats.ViewCount) AS TotalViewCount,
        SUM(PStats.AnswerCount) AS TotalAnswerCount,
        SUM(PStats.CommentCount) AS TotalCommentCount,
        SUM(PStats.TotalVoteScore) AS TotalVotesScore
    FROM 
        UserStatistics UStats
    LEFT JOIN 
        PostStatistics PStats ON UStats.UserId = PStats.OwnerUserId
    GROUP BY 
        UStats.UserId, UStats.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    BadgeCount,
    TotalBountyAmount,
    TotalPostScore,
    TotalViewCount,
    TotalAnswerCount,
    TotalCommentCount,
    TotalVotesScore
FROM 
    AggregatedStatistics
ORDER BY 
    TotalPostScore DESC, TotalViewCount DESC
LIMIT 100;
