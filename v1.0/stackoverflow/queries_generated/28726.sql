WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCount,
        QuestionsCount,
        AnswersCount,
        AvgScore,
        RANK() OVER (ORDER BY PostsCount DESC, Reputation DESC) AS Rank
    FROM 
        UserReputation
),
TopQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
TopAnswers AS (
    SELECT 
        P.Id AS AnswerId,
        P.Score,
        P.AcceptedAnswerId,
        P.ParentId,
        P.OwnerUserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 2
    GROUP BY 
        P.Id, P.Score, P.AcceptedAnswerId, P.ParentId, P.OwnerUserId, U.DisplayName
),
QuestionAnswerStats AS (
    SELECT 
        Q.QuestionId,
        Q.Title AS QuestionTitle,
        Q.CommentsCount AS QuestionComments,
        Q.UpVotes AS QuestionUpVotes,
        Q.DownVotes AS QuestionDownVotes,
        COALESCE(A.AnswerId, 'No Answers') AS AnswerId,
        COALESCE(A.DisplayName, 'No Answers') AS AnswerOwner,
        COALESCE(A.CommentsCount, 0) AS AnswerComments
    FROM 
        TopQuestions Q
    LEFT JOIN 
        TopAnswers A ON Q.QuestionId = A.ParentId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    M.PostsCount,
    M.QuestionsCount,
    M.AnswersCount,
    M.AvgScore,
    Q.QuestionTitle,
    Q.QuestionComments,
    Q.QuestionUpVotes,
    Q.QuestionDownVotes,
    Q.AnswerId,
    Q.AnswerOwner,
    Q.AnswerComments
FROM 
    MostActiveUsers M
JOIN 
    QuestionAnswerStats Q ON M.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = Q.QuestionId)
ORDER BY 
    M.Rank, U.Reputation DESC, Q.QuestionUpVotes DESC;
