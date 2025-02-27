WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgScore,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    U.AvgScore,
    U.LastPostDate,
    RP.PostId,
    RP.Title,
    RP.CreationDate
FROM 
    TopUsers U
LEFT JOIN 
    RecentPosts RP ON U.UserId = RP.OwnerDisplayName
WHERE 
    U.ScoreRank <= 10
    AND RP.PostRank = 1
ORDER BY 
    U.TotalScore DESC, RP.CreationDate DESC;
