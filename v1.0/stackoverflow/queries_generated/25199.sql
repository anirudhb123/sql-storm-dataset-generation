WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedPostsCount,
        AVG(vote.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Users u ON u.Id = p.OwnerUserId
    GROUP BY t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 1 THEN 1 END) AS TitleEdits,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 4 THEN 1 END) AS BodyEdits,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseActions
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.ClosedPostsCount,
        ts.AverageScore,
        ts.TopContributors,
        COALESCE(ps.TitleEdits, 0) AS TotalTitleEdits,
        COALESCE(ps.BodyEdits, 0) AS TotalBodyEdits,
        COALESCE(ps.CloseActions, 0) AS TotalCloseActions
    FROM TagStats ts
    LEFT JOIN PostHistoryStats ps ON ts.PostCount = ps.PostId
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    ClosedPostsCount,
    AverageScore,
    TopContributors,
    TotalTitleEdits,
    TotalBodyEdits,
    TotalCloseActions
FROM FinalResults
WHERE PostCount > 10
ORDER BY AverageScore DESC, PostCount DESC;
