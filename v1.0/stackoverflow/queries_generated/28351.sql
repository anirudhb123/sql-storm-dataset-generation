WITH TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
), 
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24)  -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY 
        ph.PostId
), 
TopPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        t.TagName,
        ps.PostCount,
        ps.TotalViews,
        ps.AverageScore,
        phs.EditCount,
        phs.LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        TagStats ps ON p.Tags LIKE CONCAT('%<', ps.TagName, '>%')
    LEFT JOIN 
        PostHistoryStats phs ON p.Id = phs.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    ORDER BY 
        ps.TotalViews DESC, 
        phs.EditCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.TagName, 
    tp.PostCount, 
    tp.TotalViews, 
    tp.AverageScore, 
    tp.EditCount, 
    tp.LastEditDate
FROM 
    TopPosts tp
WHERE 
    tp.EditCount > 5 OR tp.TotalViews > 1000
ORDER BY 
    tp.AverageScore DESC, 
    tp.PostCount DESC;
