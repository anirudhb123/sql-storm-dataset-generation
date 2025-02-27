WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.Views) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 4 THEN 1 END) AS TitleEditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 5 THEN 1 END) AS BodyEditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenedCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id
),
FinalBenchmark AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AverageScore,
        ts.TotalViews,
        ur.UserId,
        ur.Reputation,
        ur.PostCount AS UserPostCount,
        ur.TotalCommentScore,
        ur.TotalAnswerScore,
        ur.TotalQuestionScore,
        phs.LastEditDate,
        phs.TitleEditCount,
        phs.BodyEditCount,
        phs.ClosedCount,
        phs.ReopenedCount
    FROM 
        TagStats ts
    CROSS JOIN 
        UserReputation ur
    LEFT JOIN 
        PostHistoryStats phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%<', ts.TagName, '>%'))
)

SELECT 
    fb.TagName,
    fb.PostCount,
    fb.QuestionCount,
    fb.AnswerCount,
    fb.AverageScore,
    fb.TotalViews,
    fb.UserId,
    fb.Reputation,
    fb.UserPostCount,
    fb.TotalCommentScore,
    fb.TotalAnswerScore,
    fb.TotalQuestionScore,
    fb.LastEditDate,
    fb.TitleEditCount,
    fb.BodyEditCount,
    fb.ClosedCount,
    fb.ReopenedCount
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.TagName, fb.Reputation DESC;
