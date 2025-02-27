WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AverageReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseEventRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened posts
    AND 
        ph.UserId IS NOT NULL  -- Exclude system actions
),
ClosedPostDetails AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.CloseDate,
        ps.TagName,
        ts.TotalViews,
        ts.PostCount,
        ts.AverageReputation,
        ts.UserNames
    FROM 
        ClosedPosts cp
    JOIN 
        Posts p ON cp.PostId = p.Id
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        TagStatistics ts ON ts.TagName = t.TagName
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.CloseDate,
    cp.TagName,
    cp.TotalViews,
    cp.PostCount,
    cp.AverageReputation,
    cp.UserNames
FROM 
    ClosedPostDetails cp
WHERE 
    cp.CloseEventRank = 1  -- Only latest close events
ORDER BY 
    cp.CloseDate DESC,
    cp.TotalViews DESC
LIMIT 10;
