WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),

TopTaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tag_list ON true
    JOIN 
        Tags t ON t.TagName = tag_list
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    ct.LastClosedDate,
    ct.CloseCount,
    tp.Tags,
    COALESCE(NULLIF(ct.CloseCount, 0), 'No Closure Info') AS ClosureInfo,
    CASE 
        WHEN SUM(v.VoteTypeId = 2) > SUM(v.VoteTypeId = 3) THEN 'More Upvotes'
        WHEN SUM(v.VoteTypeId = 2) < SUM(v.VoteTypeId = 3) THEN 'More Downvotes'
        ELSE 'Equal Votes' 
    END AS VoteSummary
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostDetails ct ON rp.PostId = ct.PostId
LEFT JOIN 
    TopTaggedPosts tp ON rp.PostId = tp.PostId
LEFT JOIN 
    Votes v ON v.PostId = rp.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.ViewCount, ct.LastClosedDate, ct.CloseCount, tp.Tags
HAVING 
    SUM(v.VoteTypeId IN (2, 3)) > 0 -- Only include posts that have votes
ORDER BY 
    rp.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
