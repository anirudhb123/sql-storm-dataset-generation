
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        @rank := @rank + 1 AS Rank
    FROM 
        UserMetrics, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalBounty
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
