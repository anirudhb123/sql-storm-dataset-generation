
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        @row_number := @row_number + 1 AS Rank
    FROM 
        UserPostCounts, (SELECT @row_number := 0) AS r
    ORDER BY 
        PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
