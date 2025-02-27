WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- posts created in the last year
),
PostVoteDetails AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostHistoryFilter AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN pht.Name IN ('Post Locked', 'Post Closed') THEN 1 END) AS LockCloseCount
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(pvd.UpVotes, 0) AS UpVotes,
    COALESCE(pvd.DownVotes, 0) AS DownVotes,
    rp.ViewCount,
    rp.CreationDate,
    phf.LockCloseCount,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteDetails pvd ON rp.PostId = pvd.PostId
LEFT JOIN 
    PostHistoryFilter phf ON rp.PostId = phf.PostId
WHERE 
    phf.LockCloseCount > 0 -- include only posts that have been locked or closed
    AND rp.Rank <= 10 -- limiting to top 10 ranked posts
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
