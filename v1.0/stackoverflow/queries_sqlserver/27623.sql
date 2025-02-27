
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        AVG(ISNULL(p.Score, 0)) AS AverageScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        t.TagName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseEventCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.PostHistoryTypeId IN (10, 11) 
    WHERE 
        ph.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        ph.PostId
),
AggregateData AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.AverageScore,
        ts.CommentCount,
        ts.BadgeCount,
        COUNT(cp.PostId) AS ClosedCount,
        SUM(cp.CloseEventCount) AS TotalCloseEvents,
        CASE 
            WHEN COUNT(cp.PostId) > 0 THEN 'Yes'
            ELSE 'No'
        END AS HasClosedPosts
    FROM 
        TagStatistics ts
    LEFT JOIN 
        ClosedPosts cp ON ts.PostCount > 0 
    GROUP BY 
        ts.TagName, ts.PostCount, ts.TotalViews, ts.AverageScore, ts.CommentCount, ts.BadgeCount
)
SELECT 
    *,
    RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews,
    RANK() OVER (ORDER BY AverageScore DESC) AS RankByScore
FROM 
    AggregateData
ORDER BY 
    TotalViews DESC, AverageScore DESC;
