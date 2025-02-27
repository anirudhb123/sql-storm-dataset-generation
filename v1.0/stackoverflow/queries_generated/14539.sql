-- Performance Benchmarking Query

-- This query benchmarks the performance of various operations related to Posts, Users, and PostHistory 

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        PH.UserDisplayName AS LastEditor,
        COUNT(Cmt.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.LastEditorUserId = PH.UserId
    LEFT JOIN 
        Comments Cmt ON P.Id = Cmt.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, PH.UserDisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalScore,
    U.QuestionCount,
    U.AnswerCount,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.CreationDate,
    P.LastEditor,
    P.CommentCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.TotalScore DESC, 
    P.ViewCount DESC;
