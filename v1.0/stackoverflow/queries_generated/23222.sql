WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.CreationDate,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><')::int[]))) AS TagsList
    FROM 
        Posts p
    WHERE 
        p.Title IS NOT NULL 
        AND p.CreationDate >= NOW() - INTERVAL '365 days'
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 
                (SELECT CR.Name 
                 FROM CloseReasonTypes CR 
                 WHERE CR.Id = CAST(ph.Comment AS INT))
            ELSE 
                'N/A' 
        END AS CloseReason,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 12) 
        AND ph.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(cph.CloseReason, 'Open') AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistory cph 
    ON 
        rp.PostId = cph.PostId
)
SELECT 
    pe.PostId,
    pe.Score,
    pe.ViewCount,
    pe.CommentCount,
    pe.PostStatus,
    CASE 
        WHEN pe.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN pe.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Low Views' 
    END AS ViewCategory,
    CASE 
        WHEN pe.CommentCount > 10 THEN 'Highly Engaged'
        ELSE 'Less Engaged' 
    END AS EngagementCategory
FROM 
    PostEngagement pe
WHERE 
    pe.Score IS NOT NULL 
    AND pe.CommentCount IS NOT NULL 
    AND (pe.PostStatus = 'Open' OR pe.PostStatus = 'N/A')
ORDER BY 
    pe.Score DESC, pe.ViewCount DESC;

This query performs a sophisticated retrieval of posts over the last year, ranking them by score and including those that have been closed or edited. Various CTEs are employed to create interim calculations for post status, engagement, and tagging functionality. The output includes classifications based on view counts and engagement, demonstrating advanced SQL constructs such as window functions, subqueries, and complex CASE statements for enhanced analysis.
