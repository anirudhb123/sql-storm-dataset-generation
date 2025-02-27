WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Author,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'No Reasons') AS CloseReasons,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    LEFT JOIN 
        Votes v ON rp.Id = v.PostId
    GROUP BY 
        rp.Id, rp.Title, rp.Author, cp.CloseCount, cp.CloseReasons
)
SELECT 
    ps.Id,
    ps.Title,
    ps.Author,
    ps.CloseCount,
    ps.CloseReasons,
    ps.UpVotes,
    ps.DownVotes,
    ps.AverageBounty,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.CloseCount > 2 OR ps.UpVotes > 10
ORDER BY 
    ps.UpVotes DESC, ps.CloseCount ASC
LIMIT 100;
