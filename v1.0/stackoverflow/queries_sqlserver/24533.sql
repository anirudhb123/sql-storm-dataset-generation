
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -6, CAST('2024-10-01' AS DATE))
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rph.PostHistoryTypeId IS NOT NULL THEN 'Edited/Closed/Deleted'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        WHEN rp.Rank BETWEEN 4 AND 10 THEN 'Middle Post'
        ELSE 'Bottom Post'
    END AS PostCategory,
    COALESCE(CAST(rp.UpVotes AS VARCHAR(10)), '0') + ' Upvotes' AS UpvoteString
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    (rp.PostTypeId = 1 AND rp.Score > 0) 
    OR (rp.PostTypeId = 2 AND rp.ViewCount > 10) 
ORDER BY 
    rp.Score DESC,
    rp.ViewCount ASC 
OFFSET (SELECT COUNT(*) FROM RankedPosts) / 2 ROWS 
FETCH NEXT 100 ROWS ONLY;
