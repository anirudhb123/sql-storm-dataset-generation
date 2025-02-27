WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.TagId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate
), 
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ISNULL(cp.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN rp.ViewCount > 1000 THEN 'Popular'
        ELSE 'Regular'
    END AS PostType,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No views recorded'
        ELSE FORMAT(rp.ViewCount, 'N0') + ' views'
    END AS FormattedViews
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ViewRank <= 5
ORDER BY 
    rp.ViewCount DESC;
