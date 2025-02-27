
WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AverageReputation,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE '%' + Tags.TagName + '%'
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
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
        ts.TagName,
        COUNT(cp.PostId) AS ClosedPostCount
    FROM 
        TagStatistics ts
    LEFT JOIN 
        ClosedPosts cp ON ts.PostCount > 0
    GROUP BY 
        ts.TagName
    ORDER BY 
        ClosedPostCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
