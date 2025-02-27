
WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS value
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(ISNULL(p.Score, 0)) AS TotalScore
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        u.Id, up.QuestionCount, up.TotalViews, up.TotalAnswers, up.TotalScore, u.DisplayName, u.Reputation
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
