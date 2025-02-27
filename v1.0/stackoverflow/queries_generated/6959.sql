WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Questions only
        p.Score > 0 -- Only questions with a positive score
),
PostStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.AnswerCount) AS TotalAnswers,
        AVG(rp.CommentCount) AS AvgComments
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn <= 5 -- Taking only the latest 5 questions for each user
    GROUP BY 
        u.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        QuestionCount,
        TotalScore,
        TotalAnswers,
        AvgComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        PostStatistics
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tu.QuestionCount,
    tu.TotalScore,
    tu.TotalAnswers,
    tu.AvgComments,
    tu.ScoreRank
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.DisplayName = u.DisplayName
WHERE 
    tu.ScoreRank <= 10 -- Top 10 users by score
ORDER BY 
    tu.ScoreRank;
