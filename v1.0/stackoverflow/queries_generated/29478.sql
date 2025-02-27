WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        p.Id AS PostId
    FROM 
        Posts p
    WHERE 
        PostTypeId = 1  -- Only questions
),
TagAggregates AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN AnswerCount > 0 THEN PostId END) AS WithAnswersCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        TagCounts
    JOIN 
        Posts ON TagCounts.PostId = Posts.Id
    GROUP BY 
        TagName
),
TagStatistics AS (
    SELECT 
        TagName,
        QuestionCount,
        WithAnswersCount,
        TotalViews,
        CASE 
            WHEN COUNT(*) > 1 THEN 'Multiple'
            ELSE 'Single'
        END AS TagFrequency
    FROM 
        TagAggregates
    GROUP BY 
        TagName, QuestionCount, WithAnswersCount, TotalViews
)
SELECT 
    t.TagName,
    t.QuestionCount,
    t.WithAnswersCount,
    t.TotalViews,
    t.TagFrequency,
    CASE 
        WHEN t.WithAnswersCount > 0 THEN ROUND((t.WithAnswersCount::numeric / NULLIF(t.QuestionCount, 0)) * 100, 2)
        ELSE 0
    END AS AnswerRate,
    COALESCE(SUM(b.Class), 0) AS BadgeCount,
    COALESCE(SUM(u.Reputation), 0) AS TotalReputation
FROM 
    TagStatistics t
LEFT JOIN 
    Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    t.TagName, t.QuestionCount, t.WithAnswersCount, t.TotalViews, t.TagFrequency
ORDER BY 
    t.QuestionCount DESC, TotalViews DESC
LIMIT 10;
