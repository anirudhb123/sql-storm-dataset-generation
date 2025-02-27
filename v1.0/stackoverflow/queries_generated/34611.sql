WITH RECURSIVE UserPosts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        UserPosts
    WHERE 
        rn <= 5  -- Get top 5 recent posts per user
    GROUP BY 
        UserId, DisplayName
),
TagMetrics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount,
        SUM(p.Score) AS TagTotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%<'+ t.TagName +'>%'  -- Using string matching to associate tags
    GROUP BY 
        t.TagName
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) as HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
ActivePosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score,
        COALESCE(phc.HistoryCount, 0) AS HistoryCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryCounts phc ON p.Id = phc.PostId
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%<'+ t.TagName +'>%'  -- Again using string matching
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only consider posts from the last year
    GROUP BY 
        p.Id
)
SELECT 
    t.UserId, 
    t.DisplayName, 
    t.PostCount, 
    t.TotalScore, 
    t.TotalViews, 
    a.Title, 
    a.Score, 
    a.HistoryCount,
    a.TagList
FROM 
    TopUsers t
JOIN 
    ActivePosts a ON a.ID IN (SELECT postId FROM UserPosts WHERE UserId = t.UserId)
WHERE 
    t.TotalScore >= 100  -- Only interested in users with substantial score
ORDER BY 
    t.TotalScore DESC, 
    t.PostCount DESC, 
    a.Score DESC
LIMIT 10;

This SQL query performs an elaborate grouping and filtering operation across several CTEs. It retrieves the top users based on their post activity, aggregates their scores, and correlates post history counts to evaluate the engagement metric of those users. The results include metrics of active posts and associated tags while limiting the results to users with scores above a defined threshold.
