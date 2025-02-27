-- The following SQL query benchmarks string processing by extracting and aggregating various details from the StackOverflow schema.
-- It evaluates the use of text manipulations, aggregating user statistics, and common tags in questions.

WITH ExtractedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalQuestions,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.TotalBadgeClass,
    u.BadgeCount,
    q.TotalQuestions,
    q.TotalAnswers,
    q.TotalViews,
    q.TotalScore,
    t.Tag,
    COUNT(t.Tag) AS TagUsageCount
FROM 
    UserReputation u
LEFT JOIN 
    QuestionStats q ON u.UserId = q.OwnerUserId
LEFT JOIN 
    ExtractedTags t ON q.TotalQuestions > 0 -- only joining if the user has questions
GROUP BY 
    u.DisplayName, 
    u.TotalBadgeClass, 
    u.BadgeCount, 
    q.TotalQuestions, 
    q.TotalAnswers, 
    q.TotalViews, 
    q.TotalScore, 
    t.Tag
ORDER BY 
    TotalQuestions DESC, 
    TagUsageCount DESC;

