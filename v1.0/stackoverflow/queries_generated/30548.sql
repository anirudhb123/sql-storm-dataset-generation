WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        STRING_AGG(c.Text, ' | ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    COALESCE(pc.TotalComments, 0) AS TotalComments,
    COALESCE(pc.AllComments, 'No comments available') AS SampleComments,
    COALESCE(pps.WikiPostId, 'No associated wiki post') AS WikiPostId,
    CASE 
        WHEN phs.PostHistoryTypeId IS NULL THEN 'No Recent Changes'
        ELSE (SELECT Name FROM PostHistoryTypes pht WHERE pht.Id = phs.PostHistoryTypeId)
    END AS RecentChangeType
FROM 
    RecentPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    (SELECT PostId, WikiPostId FROM Tags WHERE Count > 0) pps ON p.Id = pps.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId AND phs.HistRank = 1
WHERE 
    rp.Score > 10 
    OR rp.ViewCount > 1000
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
