WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.TagId ORDER BY p.ViewCount DESC) as ViewRank,
        ROW_NUMBER() OVER (PARTITION BY p.TagId ORDER BY p.Score DESC) as ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
AggregatedTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(h.Id) AS CloseEventCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title
),
TopPosts AS (
    SELECT 
        rp.*, 
        at.PostCount, 
        at.TotalViews, 
        at.AverageScore,
        cp.CloseEventCount
    FROM 
        RankedPosts rp
    JOIN 
        AggregatedTags at ON rp.TagId = at.TagId 
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId 
    WHERE 
        rp.ViewRank <= 5 AND rp.ScoreRank <= 5
)

SELECT 
    t.TagName,
    COUNT(tp.PostId) AS TopPostCount,
    SUM(tp.ViewCount) AS TotalTopPostViews,
    AVG(tp.AverageScore) AS AverageTopPostScore,
    AVG(tp.CloseEventCount) AS AverageCloseEvents
FROM 
    TopPosts tp
JOIN 
    Tags t ON tp.Tags LIKE '%' + t.TagName + '%'
GROUP BY 
    t.TagName
ORDER BY 
    TotalTopPostViews DESC;
