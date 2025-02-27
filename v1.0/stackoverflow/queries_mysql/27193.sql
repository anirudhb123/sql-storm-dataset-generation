
WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AverageReputation,
        GROUP_CONCAT(DISTINCT Users.DisplayName ORDER BY Users.DisplayName SEPARATOR ', ') AS ActiveUsers
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        Tags.TagName
),
ClosedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        PostHistory.CreationDate AS ClosedDate,
        PostHistory.UserDisplayName AS ClosedBy,
        PostHistory.Text AS CloseReason
    FROM 
        Posts
    JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    WHERE 
        PostHistory.PostHistoryTypeId = 10  
),
TopClosedTags AS (
    SELECT 
        TagStatistics.TagName,
        COUNT(ClosedPosts.PostId) AS ClosedPostCount
    FROM 
        TagStatistics
    LEFT JOIN 
        ClosedPosts ON TagStatistics.PostCount > 0  
    GROUP BY 
        TagStatistics.TagName
    ORDER BY 
        ClosedPostCount DESC
    LIMIT 5
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageReputation,
    ts.ActiveUsers,
    tc.ClosedPostCount
FROM 
    TagStatistics ts
JOIN 
    TopClosedTags tc ON ts.TagName = tc.TagName
ORDER BY 
    ts.TotalViews DESC;
