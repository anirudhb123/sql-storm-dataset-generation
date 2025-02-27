
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes, 
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Reputation DESC
)
SELECT 
    RU.DisplayName, 
    RU.Reputation, 
    RU.PostCount, 
    RU.QuestionCount, 
    RU.AnswerCount, 
    RU.UpVotes, 
    RU.DownVotes
FROM 
    RankedUsers RU
WHERE 
    RU.Rank <= 10
ORDER BY 
    RU.Reputation DESC;
