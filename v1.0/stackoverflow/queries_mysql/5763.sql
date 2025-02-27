
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedQuestionCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        ClosedQuestionCount,
        BadgeCount,
        @rank:=IF(@reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @reputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @reputation := NULL) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    QuestionCount,
    AnswerCount,
    ClosedQuestionCount,
    BadgeCount,
    ReputationRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    Reputation DESC;
