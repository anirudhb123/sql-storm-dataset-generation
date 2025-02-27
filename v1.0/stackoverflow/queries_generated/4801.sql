WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        COALESCE(SUM(v.VoteTypeId = 6) OVER (PARTITION BY p.Id), 0) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.CloseVotes,
        (rp.Upvotes - rp.Downvotes) AS NetVotes,
        RANK() OVER (ORDER BY (rp.Upvotes - rp.Downvotes) DESC) AS VoteRank
    FROM 
        RecentPosts rp
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        PH.Comment AS ClosureReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.CloseVotes,
    ps.NetVotes,
    ps.VoteRank,
    cp.ClosureReason
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.NetVotes > 0
ORDER BY 
    ps.VoteRank
LIMIT 10;
