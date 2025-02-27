
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        AcceptedAnswerCount,
        @rank := IF(@prevReputation = Reputation AND @prevPostCount = PostCount, @rank, @rowNumber) AS Rank,
        @prevReputation := Reputation,
        @prevPostCount := PostCount,
        @rowNumber := @rowNumber + 1
    FROM 
        UserStats, (SELECT @rank := 0, @prevReputation := NULL, @prevPostCount := NULL, @rowNumber := 1) AS vars
    ORDER BY 
        Reputation DESC, PostCount DESC
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.AcceptedAnswerCount,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    RANK() OVER (ORDER BY U.PostCount DESC) AS PostCountRank
FROM 
    TopUsers U
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Reputation DESC, U.PostCount DESC;
