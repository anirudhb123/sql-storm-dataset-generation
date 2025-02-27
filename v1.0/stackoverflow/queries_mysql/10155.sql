
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId,
        PostCount,
        TotalScore,
        TotalCommentScore,
        @rankPostCount := IF(@prevPostCount = PostCount, @rankPostCount, @rankPostCount + 1) AS RankByPostCount,
        @prevPostCount := PostCount,
        @rankTotalScore := IF(@prevTotalScore = TotalScore, @rankTotalScore, @rankTotalScore + 1) AS RankByTotalScore,
        @prevTotalScore := TotalScore
    FROM 
        UserStats,
        (SELECT @rankPostCount := 0, @prevPostCount := NULL, @rankTotalScore := 0, @prevTotalScore := NULL) AS vars
    ORDER BY 
        PostCount DESC, TotalScore DESC
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    A.PostCount,
    A.TotalScore,
    A.TotalCommentScore,
    A.RankByPostCount,
    A.RankByTotalScore
FROM 
    Users U
JOIN 
    MostActiveUsers A ON U.Id = A.UserId
WHERE 
    A.RankByPostCount <= 10 OR A.RankByTotalScore <= 10
ORDER BY 
    A.RankByPostCount, A.RankByTotalScore;
