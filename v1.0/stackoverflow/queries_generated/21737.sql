WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS AvgUpvotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS AvgDownvotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostsWithPreviousClose AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(cph.CloseCount, 0) AS TotalCloseCount,
        CASE 
            WHEN COALESCE(cph.CloseCount, 0) > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        rp.ViewCount,
        rp.AvgUpvotes,
        rp.AvgDownvotes,
        rp.Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistory cph ON rp.PostId = cph.PostId
)
SELECT 
    pw.Title,
    pw.PostStatus,
    pw.ViewCount,
    pw.AvgUpvotes,
    pw.AvgDownvotes,
    COUNT(cm.Id) AS CommentCount,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
FROM 
    PostsWithPreviousClose pw
LEFT JOIN 
    Comments cm ON cm.PostId = pw.PostId
LEFT JOIN 
    Users u ON u.Id = cm.UserId AND u.Reputation > (
        SELECT 
            AVG(Reputation) 
        FROM 
            Users 
        WHERE 
            LastAccessDate >= '2023-01-01'
    )
WHERE 
    pw.TotalCloseCount < 2 -- Filtering to include only posts that have been closed less than twice
GROUP BY 
    pw.Title, pw.PostStatus, pw.ViewCount, pw.AvgUpvotes, pw.AvgDownvotes
ORDER BY 
    pw.ViewCount DESC
LIMIT 100;
