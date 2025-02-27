WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS YearlyRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.ViewCount IS NOT NULL
),
PostStatistics AS (
    SELECT 
        rp.Owner,
        COUNT(*) AS TotalQuestions,
        SUM(CASE WHEN rp.YearlyRank = 1 THEN 1 ELSE 0 END) AS TopQuestions
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.Owner
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 1
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
    HAVING 
        COUNT(ph.Id) > 0
)
SELECT 
    ps.Owner,
    ps.TotalQuestions,
    ps.TopQuestions,
    (SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1) AS AvgViews,
    pt.TagName,
    pt.PostCount,
    cp.Title AS ClosedPostTitle,
    cp.CloseCount
FROM 
    PostStatistics ps
JOIN 
    PopularTags pt ON ps.TotalQuestions > 5
LEFT JOIN 
    ClosedPosts cp ON ps.Owner = (SELECT DisplayName FROM Users WHERE Id = p.OwnerUserId)
ORDER BY 
    ps.TotalQuestions DESC, pt.PostCount DESC
LIMIT 10;
