WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Owner,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '<>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TRIM(UNNEST(string_to_array(p.Tags, '<>')))
),
ClosedPosts AS (
    SELECT 
        postId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        PostId
),
LatestComments AS (
    SELECT 
        c.PostId,
        c.Text,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Owner,
    CASE 
        WHEN rp.RankScore = 1 THEN 'Top Post' 
        WHEN rp.RowNum <= 5 THEN 'Popular' 
        ELSE 'Regular' 
    END AS Popularity,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ARRAY_AGG(DISTINCT lt.Name) AS LinkTypes,
    array_agg(DISTINCT lt.TagName ORDER BY lt.TagCount DESC) AS PopularTags,
    lc.Text AS LatestComment
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
LEFT JOIN 
    LatestComments lc ON rp.PostId = lc.PostId AND lc.CommentRank = 1
WHERE 
    rp.RankScore <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.Owner, cp.CloseCount, lc.Text
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;

