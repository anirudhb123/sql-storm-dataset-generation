WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS Contributors
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    JOIN 
        Users ON Users.Id = Posts.OwnerUserId
    WHERE 
        Posts.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        Tags.TagName
),

PopularTags AS (
    SELECT 
        TagName,
        TotalViews,
        TotalScore,
        ContributorCount = COUNT(DISTINCT Contributors) 
    FROM 
        TagStats
    WHERE 
        PostCount > 5
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),

PostHistorySummary AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        PostHistoryTypes.Name AS ChangeType,
        COUNT(PostHistory.Id) AS ChangeCount,
        MAX(PostHistory.CreationDate) AS LastChangeDate
    FROM 
        Posts
    JOIN 
        PostHistory ON PostHistory.PostId = Posts.Id
    JOIN 
        PostHistoryTypes ON PostHistory.PostHistoryTypeId = PostHistoryTypes.Id
    GROUP BY 
        Posts.Id, Posts.Title, PostHistoryTypes.Name
    ORDER BY 
        ChangeCount DESC
    LIMIT 10
)

SELECT 
    pt.TagName,
    pt.TotalViews,
    pt.TotalScore,
    phs.PostId,
    phs.Title,
    phs.ChangeType,
    phs.ChangeCount,
    phs.LastChangeDate
FROM 
    PopularTags pt
JOIN 
    PostHistorySummary phs ON phs.ChangeCount > 5
ORDER BY 
    pt.TotalViews DESC, 
    phs.LastChangeDate DESC;
