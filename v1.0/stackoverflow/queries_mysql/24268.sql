
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.CreationDate DESC
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        Score,
        CommentCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes,
        CASE 
            WHEN Score >= 10 THEN 'High Score'
            WHEN Score BETWEEN 5 AND 9 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts
    WHERE Rank <= 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS ClosedReasons,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS CHAR)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.CommentCount,
        ps.NetVotes,
        ps.ScoreCategory,
        cp.ClosedReasons,
        cp.CloseCount
    FROM 
        PostStatistics ps
    LEFT JOIN 
        ClosedPosts cp ON ps.PostId = cp.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.CommentCount,
    fr.NetVotes,
    fr.ScoreCategory,
    COALESCE(fr.ClosedReasons, 'No closure reasons') AS ClosedReasons,
    COALESCE(fr.CloseCount, 0) AS CloseCount
FROM 
    FinalReport fr
ORDER BY 
    fr.NetVotes DESC, fr.CommentCount DESC;
