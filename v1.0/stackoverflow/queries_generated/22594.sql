WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS Upvotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS Downvotes,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId AND b.Class = 1) AS GoldBadges
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND (p.Body IS NOT NULL OR p.Title IS NOT NULL)
    GROUP BY 
        p.Id, pt.Name, c.CommentCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.RankByScore,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.GoldBadges,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        cp.LastClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pm.*,
    CASE 
        WHEN pm.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    (CASE 
        WHEN pm.Score IS NULL THEN 'No Score'
        ELSE (pm.Upvotes::float / NULLIF(pm.Upvotes + pm.Downvotes, 0)) * 100
    END) AS UpvotePercentage,
    CONCAT('[', STRING_AGG(DISTINCT t.TagName, ', ' ORDER BY t.TagName), ']') AS Tags
FROM 
    PostMetrics pm
LEFT JOIN 
    Posts p ON pm.PostId = p.Id
LEFT JOIN 
    unnest(string_to_array(p.Tags, '<>')) AS tagName ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tagName
WHERE 
    pm.RankByScore <= 10 OR pm.GoldBadges > 0
GROUP BY 
    pm.PostId, pm.Title, pm.CreationDate, pm.Score, pm.RankByScore, pm.CommentCount, pm.Upvotes, pm.Downvotes, pm.GoldBadges, pm.CloseCount, pm.LastClosedDate
ORDER BY 
    pm.Score DESC, pm.CloseCount ASC
LIMIT 50;
