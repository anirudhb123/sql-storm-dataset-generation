WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Posts p2 ON p.ParentId = p2.Id
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, ',')) AS TagName) t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id
),

PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        MAX(CASE 
                WHEN ph.PostHistoryTypeId = 52 THEN ph.CreationDate 
                ELSE NULL 
            END) AS HotQuestionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TagCount,
    rp.CommentCount,
    pvi.VoteCount,
    COALESCE(pci.ClosureCount, 0) AS ClosureCount,
    pci.HotQuestionDate,
    CASE 
        WHEN pci.HotQuestionDate IS NOT NULL THEN 'Hot Question'
        ELSE 'Regular Question'
    END AS QuestionStatus,
    CASE 
        WHEN rp.ScoreRank BETWEEN 1 AND 10 THEN 'Top Rated'
        WHEN rp.ScoreRank BETWEEN 11 AND 50 THEN 'Mid Rated'
        ELSE 'Low Rated'
    END AS ScoreCategory,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'Unviewed'
        WHEN rp.ViewCount < 50 THEN 'Low Views'
        WHEN rp.ViewCount < 200 THEN 'Moderate Views'
        ELSE 'High Views'
    END AS ViewCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryInfo pci ON pci.PostId = rp.PostId
LEFT JOIN 
    Votes pv ON pv.PostId = rp.PostId
WHERE 
    rp.CommentCount > 0 OR rp.VoteCount > 0
ORDER BY 
    rp.Score DESC,
    rp.UpdateCount DESC
LIMIT 100;

