WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.AnswerCount, 0)) AS AverageAnswers,
        AVG(COALESCE(p.CommentCount, 0)) AS AverageComments,
        AVG(COALESCE(u.Reputation, 0)) AS AverageUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalBenchmark AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.TotalScore,
        ts.AverageAnswers,
        ts.AverageComments,
        ts.AverageUserReputation,
        pha.FirstCloseDate,
        pha.LastReopenDate,
        pha.CloseReopenCount
    FROM 
        TagStatistics ts
    LEFT JOIN 
        PostHistoryAnalysis pha ON ts.PostCount > 0 AND ts.PostCount = (
            SELECT COUNT(*) FROM Posts p WHERE p.Tags LIKE CONCAT('%<', ts.TagName, '>%')
        )
    ORDER BY 
        ts.TotalViews DESC, ts.TotalScore DESC
)

SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    AverageAnswers,
    AverageComments,
    AverageUserReputation,
    FirstCloseDate,
    LastReopenDate,
    CloseReopenCount
FROM 
    FinalBenchmark
WHERE 
    PostCount > 0
AND 
    TotalViews > 1000
AND 
    AverageUserReputation > 50
ORDER BY 
    TotalScore DESC, PostCount DESC;
