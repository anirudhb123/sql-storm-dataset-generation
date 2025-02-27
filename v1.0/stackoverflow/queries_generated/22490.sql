WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01'
        AND p.Score IS NOT NULL
),
UserVoteDetails AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        COALESCE(u.UpVotes, 0) AS UpVotes,
        COALESCE(u.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN cr.CloseReason IS NOT NULL THEN cr.CloseReason
            ELSE 'Not Closed'
        END AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVoteDetails u ON rp.PostId = u.PostId
    LEFT JOIN 
        ClosedPostReasons cr ON rp.PostId = cr.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CloseReason,
    CASE 
        WHEN ps.CloseReason != 'Not Closed' THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.RankByScore <= 10
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
OFFSET 5 ROWS; -- Skip the first 5 results for more interesting benchmarking

-- Performance benchmarking: measure execution time of this query execution in your SQL environment.
