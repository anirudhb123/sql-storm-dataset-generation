WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 month'
),
tag_summary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5 -- only include tags with more than 5 posts
),
closed_posts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Close action
    GROUP BY 
        ph.PostId
),
final_results AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ts.TagName,
        ts.PostCount,
        ts.AvgUserReputation,
        cp.CloseCount,
        cp.FirstCloseDate,
        CASE 
            WHEN cp.CloseCount IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS PostStatus
    FROM 
        ranked_posts rp
    LEFT JOIN 
        tag_summary ts ON rp.PostId = (SELECT MIN(p.Id)
                                         FROM Posts p
                                         WHERE p.Tags LIKE '%' || ts.TagName || '%')
    LEFT JOIN 
        closed_posts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.RankByScore <= 10 -- top 10 posts by score per type
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.TagName,
    f.PostCount,
    f.AvgUserReputation,
    f.CloseCount,
    f.FirstCloseDate,
    f.PostStatus,
    CASE 
        WHEN f.TagName IS NULL THEN 'No Tag Associated'
        ELSE 'Tag Associated'
    END AS TagStatus
FROM 
    final_results f
ORDER BY 
    f.Score DESC,
    f.CreationDate ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY; -- pagination skipping first 5 results
