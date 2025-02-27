
WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TagPopularity AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount 
    FROM 
        PostTags 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount 
    FROM 
        TagPopularity 
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
UserReputationStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        up.QuestionCount,
        up.TotalViews,
        up.TotalAnswers,
        up.TotalScore,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        UserPostStats up ON u.Id = up.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, up.QuestionCount, up.TotalViews, up.TotalAnswers, up.TotalScore, u.Reputation
),
OverallStats AS (
    SELECT 
        AVG(QuestionCount) AS AvgQuestions,
        AVG(TotalViews) AS AvgViews,
        AVG(TotalAnswers) AS AvgAnswers,
        AVG(TotalScore) AS AvgScore,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        UserReputationStats
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.QuestionCount,
    u.TotalViews,
    u.TotalAnswers,
    u.TotalScore,
    (u.TotalScore - os.AvgScore) AS ScoreDifference,
    (u.TotalViews - os.AvgViews) AS ViewDifference,
    COALESCE(tt.Tag, 'General') AS PopularTag
FROM 
    UserReputationStats u
CROSS JOIN 
    OverallStats os
LEFT JOIN 
    TopTags tt ON u.QuestionCount > os.AvgQuestions
ORDER BY 
    u.TotalScore DESC;
