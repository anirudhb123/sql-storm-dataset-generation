WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id
    GROUP BY p.Id
),
BenchmarkResults AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AvgUserReputation,
        ts.Contributors,
        ts.TotalViews,
        COUNT(pm.PostId) AS RelatedPosts,
        SUM(pm.CommentCount) AS TotalComments,
        SUM(pm.VoteCount) AS TotalVotes,
        MAX(pm.CloseCount) AS MaxCloseCount
    FROM TagStats ts
    LEFT JOIN PostMetrics pm ON ts.TagName IN (SELECT unnest(string_to_array(p.Tags, '>'))::text) 
    GROUP BY ts.TagName, ts.PostCount, ts.AvgUserReputation, ts.Contributors, ts.TotalViews
)
SELECT 
    *,
    (TotalComments::decimal / NULLIF(PostCount, 0)) AS CommentsPerPost,
    (TotalVotes::decimal / NULLIF(PostCount, 0)) AS VotesPerPost
FROM BenchmarkResults
ORDER BY PostCount DESC, AvgUserReputation DESC;
