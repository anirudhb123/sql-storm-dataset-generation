WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Selecting only questions

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        CTE.Level + 1
    FROM Posts P
    JOIN RecursiveCTE CTE ON P.ParentId = CTE.PostId  -- Hierarchical relationship
)

, UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions only
    GROUP BY U.Id, U.DisplayName, U.Reputation
)

, VotesCTE AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeletionVotes,
        COUNT(*) AS TotalVotes
    FROM Votes V
    GROUP BY V.UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    S.QuestionCount,
    S.TotalScore,
    S.TotalViews,
    COALESCE(V.UpVotes, 0) AS UpVotes,
    COALESCE(V.DownVotes, 0) AS DownVotes,
    COALESCE(V.DeletionVotes, 0) AS DeletionVotes,
    COALESCE(V.TotalVotes, 0) AS TotalVotes,
    COUNT(DISTINCT CTE.PostId) AS AnsweredQuestions
FROM UserStats S
JOIN Users U ON S.UserId = U.Id
LEFT JOIN VotesCTE V ON U.Id = V.UserId
LEFT JOIN RecursiveCTE CTE ON U.Id = CTE.OwnerUserId  -- Joining to get answered questions
GROUP BY U.Id, U.DisplayName, U.Reputation, S.QuestionCount, S.TotalScore, S.TotalViews
ORDER BY S.TotalScore DESC, S.QuestionCount DESC, U.Reputation DESC;
