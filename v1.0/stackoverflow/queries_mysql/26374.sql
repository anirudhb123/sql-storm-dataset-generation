
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t1,
            (SELECT @row := 0) t2) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        Tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        TotalViews,
        TotalScore,
        @rank1 := @rank1 + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank1 := 0) r
    ORDER BY TotalScore DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        TotalViews,
        TotalAnswers,
        @rank2 := @rank2 + 1 AS Rank
    FROM 
        UserEngagement, (SELECT @rank2 := 0) r
    ORDER BY TotalViews DESC
)
SELECT 
    tt.Tag,
    tt.QuestionCount,
    tt.TotalViews,
    tt.TotalScore,
    tu.DisplayName AS TopUser,
    tu.QuestionsAsked,
    tu.TotalViews AS UserTotalViews,
    tu.TotalAnswers 
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tt.Rank = tu.Rank
WHERE 
    tt.Rank <= 5;
