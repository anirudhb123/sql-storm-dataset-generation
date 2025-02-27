
WITH User_Reputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT P.Id) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
Top_Users AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        @row_number := @row_number + 1 AS Rank
    FROM 
        User_Reputation, (SELECT @row_number := 0) AS init
    ORDER BY 
        Reputation DESC
),
Post_Scores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS Owner,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS TotalDownVotes,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, U.DisplayName
),
User_Activity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsPosted,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersPosted,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsPosted
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    UA.QuestionsPosted,
    UA.AnswersPosted,
    UA.CommentsPosted,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PS.CommentCount
FROM 
    Top_Users TU
JOIN 
    User_Activity UA ON TU.UserId = UA.UserId
JOIN 
    Post_Scores PS ON UA.AnswersPosted > 0
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank;
