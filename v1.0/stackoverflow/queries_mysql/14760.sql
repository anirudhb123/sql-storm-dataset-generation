
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalPostScore,
        SUM(P.ViewCount) AS TotalPostViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalPostScore,
        TotalPostViews,
        @rank_score := IF(TotalPostScore IS NULL, NULL, @rank_score + 1) AS ScoreRank,
        @rank_views := IF(TotalPostViews IS NULL, NULL, @rank_views + 1) AS ViewsRank
    FROM 
        UserPostStats,
        (SELECT @rank_score := 0, @rank_views := 0) AS r
    ORDER BY 
        TotalPostScore DESC, TotalPostViews DESC
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalPostScore,
    TotalPostViews,
    ScoreRank,
    ViewsRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR ViewsRank <= 10
ORDER BY 
    ScoreRank, ViewsRank;
