
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(V.BountyAmount) AS AverageBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
        TotalScore, 
        AverageBounty, 
        BadgeCount,
        @row_number := IF(@prev_score = TotalScore, @row_number, @row_number + 1) AS ScoreRank,
        @prev_score := TotalScore,
        @post_rank := IF(@prev_post_count = PostCount, @post_rank, @post_rank + 1) AS PostRank,
        @prev_post_count := PostCount
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_score := NULL, @post_rank := 0, @prev_post_count := NULL) AS vars
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
    AverageBounty, 
    BadgeCount,
    ScoreRank,
    PostRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR PostRank <= 10
ORDER BY 
    GREATEST(ScoreRank, PostRank);
