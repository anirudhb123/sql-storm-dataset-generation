
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        @postRank := IF(@prevPostCount = PostCount, @postRank, @rowNum) AS PostRank,
        @prevPostCount := PostCount,
        @rowNum := @rowNum + 1,
        @scoreRank := IF(@prevTotalScore = TotalScore, @scoreRank, @rowNumScore) AS ScoreRank,
        @prevTotalScore := TotalScore,
        @rowNumScore := @rowNumScore + 1
    FROM 
        UserPostCounts, 
        (SELECT @rowNum := 0, @postRank := 0, @prevPostCount := NULL, @rowNumScore := 0, @scoreRank := 0, @prevTotalScore := NULL) AS vars
    ORDER BY 
        PostCount DESC, TotalScore DESC
)
SELECT 
    u.DisplayName,
    uc.PostCount,
    uc.QuestionCount,
    uc.AnswerCount,
    uc.TotalViews,
    uc.TotalScore,
    t.PostRank,
    t.ScoreRank
FROM 
    Users u
JOIN 
    UserPostCounts uc ON u.Id = uc.UserId
JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    t.PostRank <= 10 OR t.ScoreRank <= 10
ORDER BY 
    t.PostRank, t.ScoreRank;
