WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1  -- Filtering to only questions
),
PostKeywordStats AS (
    SELECT 
        rp.PostId,
        COUNT(*) AS KeywordCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        RecentPosts rp
    CROSS JOIN 
        LATERAL unnest(string_to_array(rp.Tags, ',')) AS tag
    LEFT JOIN 
        Tags t ON trim(both ' ' from tag) = t.TagName
    GROUP BY 
        rp.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName AS ClosedBy,
        r.TagList,
        rp.ViewCount,
        rp.Score
    FROM 
        PostHistory ph
    JOIN 
        PostKeywordStats r ON ph.PostId = r.PostId
    JOIN 
        RecentPosts rp ON ph.PostId = rp.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  -- Posts that were closed
)
SELECT 
    cp.PostId,
    rp.Title,
    cp.ClosedBy,
    cp.CreationDate AS ClosedDate,
    cp.TagList,
    cp.ViewCount,
    cp.Score,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = cp.PostId) AS CommentCount
FROM 
    ClosedPosts cp
JOIN 
    RecentPosts rp ON cp.PostId = rp.PostId
ORDER BY 
    cp.ClosedDate DESC, cp.Score DESC;
