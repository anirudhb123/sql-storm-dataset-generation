
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViewCount,
        @rankByScore := IF(@prevTotalScore = TotalScore, @rankByScore, @rowNumber) AS RankByScore,
        @prevTotalScore := TotalScore,
        @rowNumber := @rowNumber + 1 AS rowNumber,
        @rankByPosts := IF(@prevPostCount = PostCount, @rankByPosts, @rowNumberPosts) AS RankByPosts,
        @prevPostCount := PostCount,
        @rowNumberPosts := @rowNumberPosts + 1
    FROM 
        UserPostStats, 
        (SELECT @rankByScore := 0, @rowNumber := 1, @prevTotalScore := NULL, @rankByPosts := 0, @rowNumberPosts := 1, @prevPostCount := NULL) AS vars
    ORDER BY 
        TotalScore DESC, PostCount DESC
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    AvgViewCount,
    RankByScore,
    RankByPosts
FROM 
    TopUsers
WHERE 
    RankByScore <= 10 OR RankByPosts <= 10
ORDER BY 
    RankByScore, RankByPosts;
