WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AvgScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(c.CreationDate IS NOT NULL) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 6)
)
SELECT 
    ts.TagName,
    ts.PostCount AS TotalPostsWithTag,
    ts.TotalViews AS TotalViewsForTag,
    ts.CommentCount AS TotalCommentsForTag,
    ts.AvgScore AS AverageScoreForTag,
    ua.DisplayName AS UserDisplayName,
    ua.PostCount AS UserPostCount,
    ua.TotalBounties AS UserTotalBounties,
    ua.BadgeCount AS UserBadgeCount,
    ua.TotalComments AS UserTotalComments,
    COUNT(ph.PostId) AS HistoryCount
FROM 
    TagStatistics ts
JOIN 
    UserActivity ua ON ts.PostCount > 0
LEFT JOIN 
    PostHistoryDetails ph ON ph.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
GROUP BY 
    ts.TagName, ua.DisplayName, ts.PostCount, ts.TotalViews, ts.CommentCount, ts.AvgScore, ua.PostCount, ua.TotalBounties, ua.BadgeCount, ua.TotalComments
ORDER BY 
    ts.TotalViews DESC, ua.PostCount DESC;
