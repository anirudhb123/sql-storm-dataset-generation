
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @rank := @rank + 1) AS ScoreRank,
        @prevScore := TotalScore,
        @PostRank := IF(@prevPostCount = PostCount, @PostRank, @postRank := @postRank + 1) AS PostRank,
        @prevPostCount := PostCount
    FROM UserPosts, (SELECT @ScoreRank := 0, @PostRank := 0, @rank := 0, @prevScore := NULL, @prevPostCount := NULL) r
    ORDER BY TotalScore DESC, PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    ScoreRank,
    PostRank
FROM TopUsers
WHERE ScoreRank <= 10 OR PostRank <= 10
ORDER BY ScoreRank, PostRank;
