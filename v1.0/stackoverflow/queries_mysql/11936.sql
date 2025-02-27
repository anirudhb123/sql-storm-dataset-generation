
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
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
        TotalViews,
        AvgScore,
        QuestionCount,
        AnswerCount,
        @rankPostCount := IF(@prevPostCount = PostCount, @rankPostCount, @rankPostCount + 1) AS RankByPostCount,
        @prevPostCount := PostCount,
        @rankTotalViews := IF(@prevTotalViews = TotalViews, @rankTotalViews, @rankTotalViews + 1) AS RankByTotalViews,
        @prevTotalViews := TotalViews,
        @rankAvgScore := IF(@prevAvgScore = AvgScore, @rankAvgScore, @rankAvgScore + 1) AS RankByAvgScore,
        @prevAvgScore := AvgScore
    FROM 
        UserPostStats, (SELECT @rankPostCount := 0, @prevPostCount := NULL, @rankTotalViews := 0, @prevTotalViews := NULL, @rankAvgScore := 0, @prevAvgScore := NULL) AS vars
    ORDER BY 
        PostCount DESC, TotalViews DESC, AvgScore DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    AvgScore,
    QuestionCount,
    AnswerCount,
    RankByPostCount,
    RankByTotalViews,
    RankByAvgScore
FROM 
    TopUsers
WHERE 
    RankByPostCount <= 10 OR RankByTotalViews <= 10 OR RankByAvgScore <= 10
ORDER BY 
    RankByPostCount, RankByTotalViews, RankByAvgScore;
