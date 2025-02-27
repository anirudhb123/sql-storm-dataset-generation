WITH RecursiveTopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation > 0
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletedDate,
        COUNT(*) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        ps.TotalViews,
        phs.EditCount,
        ps.AverageScore,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    LEFT JOIN TagStats ps ON ps.PostCount > 0
    LEFT JOIN PostHistorySummary phs ON phs.PostId = p.Id
    WHERE p.AcceptedAnswerId IS NOT NULL
)
SELECT 
    u.DisplayName AS TopUser,
    u.Reputation AS UserReputation,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS PostViewCount,
    ts.TagName,
    ts.PostCount AS PostsWithTagCount,
    phs.ClosedDate,
    phs.DeletedDate
FROM RecursiveTopUsers u
JOIN TopPosts tp ON u.Id = tp.OwnerUserId
JOIN TagStats ts ON ts.PostCount > 0
LEFT JOIN PostHistorySummary phs ON phs.PostId = tp.Id
WHERE u.Rank <= 10
ORDER BY u.Reputation DESC, tp.ViewCount DESC;
