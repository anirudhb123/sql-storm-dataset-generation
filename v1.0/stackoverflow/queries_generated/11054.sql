-- Performance Benchmarking Query

WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
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
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        COALESCE(CR.Name, 'Open') AS CloseReason
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    LEFT JOIN 
        CloseReasonTypes CR ON PH.Comment::int = CR.Id AND PH.PostHistoryTypeId IN (10, 11) 
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
VoteStatistics AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    U.TotalViews,
    U.BadgeCount,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.Score AS PostScore,
    PS.ViewCount AS PostViewCount,
    PS.AnswerCount AS PostAnswerCount,
    PS.CommentCount AS PostCommentCount,
    PS.FavoriteCount AS PostFavoriteCount,
    PS.CloseReason,
    VS.Upvotes,
    VS.Downvotes,
    VS.TotalVotes
FROM 
    UserStatistics U
JOIN 
    PostStatistics PS ON PS.PostId IN (SELECT PostId FROM Votes WHERE UserId = U.UserId)
LEFT JOIN 
    VoteStatistics VS ON VS.PostId = PS.PostId
ORDER BY 
    U.Reputation DESC, U.TotalScore DESC;
