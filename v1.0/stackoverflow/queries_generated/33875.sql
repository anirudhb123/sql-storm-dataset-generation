WITH RecursiveTags AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        0 AS Level
    FROM Tags
    WHERE IsRequired = 1
    
    UNION ALL
    
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        rt.Level + 1
    FROM Tags t
    JOIN RecursiveTags rt ON rt.ExcerptPostId = t.Id
    WHERE t.IsModeratorOnly = 1
),
UserPostStats AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS TitleEditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM PostHistory ph
    GROUP BY ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserID,
        ups.DisplayName,
        ups.PostCount,
        ups.CommentCount,
        ups.PositivePostCount,
        ups.NegativePostCount,
        ups.TotalViews,
        ups.AvgScore,
        phs.EditCount,
        phs.TitleEditCount,
        phs.CloseCount,
        phs.ReopenCount,
        ROW_NUMBER() OVER (ORDER BY ups.TotalViews DESC) AS Rank
    FROM UserPostStats ups
    LEFT JOIN PostHistoryStats phs ON ups.UserID = phs.UserId
)
SELECT 
    c.TagName,
    cs.DisplayName,
    cs.PostCount,
    cs.CommentCount,
    cs.PositivePostCount,
    cs.NegativePostCount,
    cs.TotalViews,
    cs.AvgScore,
    cs.EditCount,
    cs.TitleEditCount,
    cs.CloseCount,
    cs.ReopenCount
FROM CombinedStats cs
LEFT JOIN RecursiveTags rt ON cs.UserID = rt.Id
WHERE cs.Rank <= 10
ORDER BY cs.TotalViews DESC, cs.DisplayName;
