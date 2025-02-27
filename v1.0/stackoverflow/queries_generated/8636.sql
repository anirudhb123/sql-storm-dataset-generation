WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgScore,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Bounty start or close
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
        AvgScore,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
        RANK() OVER (ORDER BY AvgScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgScore,
    TotalBounty,
    PostRank,
    QuestionRank,
    ScoreRank,
    (PostRank + QuestionRank + ScoreRank) AS OverallRank
FROM 
    TopUsers
WHERE 
    OverallRank <= 10
ORDER BY 
    OverallRank;
