
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT A.Id) AS AcceptedAnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeletionCount,
        SUM(CASE WHEN V.VoteTypeId = 16 THEN 1 ELSE 0 END) AS ApproveEditCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1
    LEFT JOIN 
        Posts A ON A.AcceptedAnswerId = P.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AcceptedAnswerCount,
        UpVotesCount,
        DownVotesCount,
        @rankByQuestions := IF(@prevQuestionCount = QuestionCount, @rankByQuestions, @rankByQuestions + 1) AS RankByQuestions,
        @prevQuestionCount := QuestionCount,
        @rankByAcceptedAnswers := IF(@prevAcceptedAnswerCount = AcceptedAnswerCount, @rankByAcceptedAnswers, @rankByAcceptedAnswers + 1) AS RankByAcceptedAnswers,
        @prevAcceptedAnswerCount := AcceptedAnswerCount,
        @rankByVoteDifference := IF(@prevVoteDifference = UpVotesCount - DownVotesCount, @rankByVoteDifference, @rankByVoteDifference + 1) AS RankByVoteDifference,
        @prevVoteDifference := UpVotesCount - DownVotesCount
    FROM 
        UserActivity,
        (SELECT @rankByQuestions := 0, @prevQuestionCount := NULL, @rankByAcceptedAnswers := 0, @prevAcceptedAnswerCount := NULL, @rankByVoteDifference := 0, @prevVoteDifference := NULL) AS vars
    ORDER BY 
        QuestionCount DESC, AcceptedAnswerCount DESC, UpVotesCount - DownVotesCount DESC
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AcceptedAnswerCount,
    UpVotesCount,
    DownVotesCount,
    RankByQuestions,
    RankByAcceptedAnswers,
    RankByVoteDifference,
    CASE 
        WHEN RankByQuestions = 1 THEN 'Top Question Asker'
        WHEN RankByAcceptedAnswers = 1 THEN 'Top Answer Provider'
        WHEN RankByVoteDifference = 1 THEN 'Most Positive Impact'
        ELSE 'Contributor'
    END AS UserCategory
FROM 
    TopUsers
WHERE 
    RankByQuestions <= 10 OR RankByAcceptedAnswers <= 10 OR RankByVoteDifference <= 10
ORDER BY 
    RankByQuestions, RankByAcceptedAnswers, RankByVoteDifference;
