WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        pv.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes pv
    JOIN 
        VoteTypes vt ON pv.VoteTypeId = vt.Id
    GROUP BY 
        pv.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Reputation,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COUNT(cp.Comment) AS ClosureCount,
    STRING_AGG(DISTINCT cp.Comment, ', ') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.Rank = 1
GROUP BY 
    rp.Id, rp.Title, rp.ViewCount, rp.Score, rp.Reputation
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
