WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(pg.ViewCount, 0), NULL) AS ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    LEFT JOIN 
        (SELECT PostId, SUM(ViewCount) AS ViewCount 
         FROM Posts 
         WHERE CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
         GROUP BY PostId) pg ON p.Id = pg.PostId
    WHERE 
        p.CreationDate < CURRENT_TIMESTAMP 
        AND p.PostTypeId IN (1, 2) -- Questions and Answers
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        CASE 
            WHEN COUNT(ph.Id) > 2 THEN 'Moderately Edited'
            WHEN COUNT(ph.Id) IS NULL THEN 'Not Edited'
            ELSE 'Slightly Edited'
        END AS EditStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
    HAVING 
        AVG(rp.Score) > 10 OR (rp.ViewCount IS NOT NULL AND rp.ViewCount > 100)
),
AggregatedTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.EditStatus,
    at.Tags,
    (DATEDIFF(NOW(), fp.CreationDate) / NULLIF(COALESCE(fp.ViewCount, 1), 0)) AS DaysPerView,
    CASE 
        WHEN fp.ViewCount IS NULL THEN 'No Views'
        WHEN fp.ViewCount > 100 THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    AggregatedTags at ON fp.PostId = at.PostId
WHERE 
    fp.EditStatus IN ('Moderately Edited', 'Not Edited')
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC
LIMIT 50;
