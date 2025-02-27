-- Performance Benchmarking Query for StackOverflow Schema

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(V.CreationDate IS NOT NULL) AS VoteCount,
        SUM(B.Id IS NOT NULL) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.CreationDate IS NOT NULL) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, '><')) AS TagName AS T
    GROUP BY 
        P.Id
)
SELECT 
    UA.DisplayName,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.CommentCount,
    UA.VoteCount,
    UA.BadgeCount,
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.Tags,
    PS.TotalComments,
    PS.VoteCount AS PostVoteCount
FROM 
    UserActivity UA
JOIN 
    PostStatistics PS ON UA.UserId = PS.PostId
ORDER BY 
    UA.Reputation DESC, PS.ViewCount DESC;
