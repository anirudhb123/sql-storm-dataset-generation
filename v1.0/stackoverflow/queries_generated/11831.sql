-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.VoteTypeId = 2) AS UpvoteCount,
        SUM(V.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CM.Id) AS CommentCount,
        SUM(B.Id IS NOT NULL) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id
)
SELECT 
    S.UserId,
    S.DisplayName,
    S.PostCount,
    S.QuestionCount,
    S.AnswerCount,
    S.UpvoteCount,
    S.DownvoteCount,
    P.PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.ViewCount AS PostViewCount,
    P.Score AS PostScore,
    P.CommentCount AS PostCommentCount,
    P.BadgeCount
FROM 
    UserStats S
JOIN 
    PostStats P ON S.UserId = P.OwnerUserId
ORDER BY 
    S.Reputation DESC, P.ViewCount DESC
LIMIT 1000;
