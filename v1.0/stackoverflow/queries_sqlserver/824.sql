
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) OVER (PARTITION BY p.Id) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CloseCount,
    CASE 
        WHEN rp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
