
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 2 YEAR 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
PostUpvotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS UpvoteCount
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId = 2
    GROUP BY 
        v.PostId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        PHT.Name AS HistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(rp.Rank, 0) AS PostRank,
    COALESCE(up.UpvoteCount, 0) AS UpvoteCount,
    rp.Tags,
    COUNT(rph.UserId) AS HistoryChanges
FROM 
    RankedPosts rp
LEFT JOIN 
    PostUpvotes up ON rp.PostId = up.PostId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    (rp.Rank <= 10 OR rp.Score >= 100) 
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Rank, up.UpvoteCount, rp.Tags
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
