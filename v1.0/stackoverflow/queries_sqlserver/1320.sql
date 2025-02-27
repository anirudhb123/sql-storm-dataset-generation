
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, '2024-10-01 12:34:56')
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pt.TotalViews, 0) AS TagViews,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE '%' + pt.TagName + '%'
WHERE 
    rp.CommentCount > 10
ORDER BY 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
