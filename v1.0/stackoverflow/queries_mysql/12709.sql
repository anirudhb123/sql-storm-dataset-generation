
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        AnswerCount,
        @row_num_post := IF(@prev_post = PostCount, @row_num_post, @row_num_post + 1) AS PostRank,
        @prev_post := PostCount,
        @row_num_score := IF(@prev_score = TotalScore, @row_num_score, @row_num_score + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM UserPostCounts, (SELECT @row_num_post := 0, @prev_post := NULL, @row_num_score := 0, @prev_score := NULL) AS vars
    WHERE PostCount > 0
    ORDER BY PostCount DESC, TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AnswerCount,
    PostRank,
    ScoreRank
FROM TopUsers
WHERE PostRank <= 10 OR ScoreRank <= 10
ORDER BY PostRank, ScoreRank;
