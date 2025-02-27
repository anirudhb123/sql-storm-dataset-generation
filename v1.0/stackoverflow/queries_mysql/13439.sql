
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalUpvotes,
        TotalDownvotes,
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalUpvotes,
    TotalDownvotes,
    ReputationRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    Reputation DESC;
